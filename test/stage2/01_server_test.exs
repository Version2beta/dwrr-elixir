# Complete; do not change.
defmodule Dwrr.Stage2.ServerTest do
  use ExUnit.Case, async: false
  import Dwrr.TestSupport, only: [item: 1, item: 2]
  import ExUnit.CaptureLog
  alias Dwrr.Server, as: S
  @moduletag timeout: 15_000

  test "initializes and forwards registered name and standard options" do
    {:ok, pid} = S.start_link(2, name: __MODULE__, debug: [])
    on_exit(fn -> if Process.alive?(pid), do: GenServer.stop(pid) end)
    assert Process.whereis(__MODULE__) == pid
    assert {:ok, [], state} = S.take(__MODULE__, 0)
    assert state === Dwrr.new(2)
    assert {:error, {:already_started, ^pid}} = S.start_link(9, name: __MODULE__)
    assert {:ok, [], ^state} = S.take(pid, 0)
  end

  test "every operation replies exactly and stores its operation-specific state" do
    pid = start_supervised!({S, 2})

    ops = [
      {:enqueue, 0, [item(:a, 1), item(:b, 2)]},
      {:set_quantum, 0, 3},
      {:take, 1},
      {:remove_head, 0},
      {:enqueue, 1, [item(nil)]},
      {:drain_queue, 1},
      :add_queue,
      :remove_queue,
      :remove_queue,
      :remove_queue,
      :remove_queue,
      :add_queue
    ]

    Enum.reduce(ops, Dwrr.new(2), fn op, state ->
      args = if is_atom(op), do: [op], else: Tuple.to_list(op)
      [name | rest] = args
      expected = apply(Dwrr, name, [state | rest])
      assert apply(S, name, [pid | rest]) === expected

      next =
        case {name, expected} do
          {:add_queue, {_, next}} -> next
          {:remove_queue, next} -> next
          {_, {:ok, next}} -> next
          {_, {:ok, _, next}} -> next
        end

      assert {:ok, [], ^next} = S.take(pid, 0)
      next
    end)
  end

  test "all shared errors preserve the owned state and permit continuation" do
    pid = start_supervised!({S, 1})
    {:ok, before} = S.enqueue(pid, 0, [item(:kept)])
    m = Dwrr.TestSupport.max_cost()

    for {op, expected} <- [
          {{:enqueue, 9, [item(:x, 0)]}, :invalid_index},
          {{:enqueue, 0, [item(:x), item(:bad, 0)]}, :zero_cost},
          {{:enqueue, 0, [item(:x, m + 1)]}, :cost_too_large},
          {{:set_quantum, 0, 0}, :zero_quantum},
          {{:set_quantum, 0, m + 1}, :quantum_too_large},
          {{:remove_head, -1}, :invalid_index},
          {{:drain_queue, 1}, :invalid_index},
          {{:take, -1}, :negative_take}
        ] do
      [name | args] = Tuple.to_list(op)
      assert apply(S, name, [pid | args]) == {:error, expected}
      assert {:ok, [], ^before} = S.take(pid, 0)
    end

    assert {:ok, [%Dwrr.Scheduled{value: :kept}], _} = S.take(pid, 1)
  end

  test "concurrent callers serialize whole operations with no lost enqueue or take" do
    pid = start_supervised!({S, 1})
    tasks = for i <- 1..40, do: Task.async(fn -> S.enqueue(pid, 0, [item(i)]) end)
    snapshots = Enum.map(tasks, &Task.await/1)
    assert Enum.sort(Enum.map(snapshots, fn {:ok, s} -> s.total end)) == Enum.to_list(1..40)
    tasks = for _ <- 1..40, do: Task.async(fn -> S.take(pid, 1) end)

    values =
      Enum.map(tasks, fn task ->
        assert {:ok, [%Dwrr.Scheduled{value: v}], _} = Task.await(task)
        v
      end)

    assert Enum.sort(values) == Enum.to_list(1..40)
    assert {:ok, [], state} = S.take(pid, 1)
    assert state.total == 0
  end

  test "outside-domain faults terminate server and call exits, without an error translation" do
    capture_log(fn ->
      for op <- [
            {:take, :bad},
            {:enqueue, 0, [item(:x, -1)]},
            {:set_quantum, 0, -1},
            {:remove_head, nil},
            {:drain_queue, nil}
          ] do
        {:ok, pid} = S.start_link(1)
        Process.unlink(pid)
        ref = Process.monitor(pid)
        [name | args] = Tuple.to_list(op)
        reason = catch_exit(apply(S, name, [pid | args]))
        assert match?({{%ArgumentError{}, _}, _}, reason)
        assert_receive {:DOWN, ^ref, :process, ^pid, {%ArgumentError{}, _}}
      end
    end)
  end

  test "caller-owned supervisor restarts fresh using original count; no implicit child" do
    assert Application.spec(:dwrr, :mod) == []

    sup =
      start_supervised!(%{
        id: :owner,
        start: {Supervisor, :start_link, [[], [strategy: :one_for_one]]}
      })

    {:ok, first} = Supervisor.start_child(sup, {S, 2})
    assert {:ok, _} = S.enqueue(first, 0, [item(:lost)])
    assert {2, _} = S.add_queue(first)
    :ok = Supervisor.terminate_child(sup, S)
    {:ok, restarted} = Supervisor.restart_child(sup, S)
    refute restarted == first
    assert {:ok, [], fresh} = S.take(restarted, 1)
    assert fresh === Dwrr.new(2)
  end

  test "default call timeout is used; no retry; invalid initialization fails" do
    capture_log(fn ->
      old = Process.flag(:trap_exit, true)

      try do
        assert {:error, {%ArgumentError{}, _}} = S.start_link(-1)
      after
        Process.flag(:trap_exit, old)
      end
    end)

    # A deliberately inert owner-controlled GenServer: count received calls, never reply.
    fake =
      spawn_link(fn ->
        receive do
          {:"$gen_call", _from, request} ->
            send(self(), {:seen, request})

            receive do
              {:barrier, caller, ref} ->
                send(caller, {:barrier_ready, ref})

                receive do
                  :stop -> :ok
                end
            end
        end
      end)

    started = System.monotonic_time(:millisecond)
    assert {:timeout, {GenServer, :call, [^fake, _, 5000]}} = catch_exit(S.take(fake, 1))
    elapsed = System.monotonic_time(:millisecond) - started
    assert elapsed >= 4_900

    # Timeout alone does not prove the fake has executed its self-send. The ack
    # follows that send in the fake's execution order. Calls and this barrier
    # from this caller reach the fake in sender order, so any retry remains
    # queued too. Selective receive consumes only the barrier, not the marker.
    barrier = make_ref()
    send(fake, {:barrier, self(), barrier})
    assert_receive {:barrier_ready, ^barrier}
    {:messages, messages} = Process.info(fake, :messages)
    assert [{:seen, _request}] = messages
    send(fake, :stop)
  end
end
