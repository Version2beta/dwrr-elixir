defmodule Dwrr.DomainValidationTest do
  use ExUnit.Case, async: true

  @max_cost 9_223_372_036_854_775_807

  setup do
    {:ok, s} = Dwrr.set_quantum(Dwrr.new(1), 0, 4)
    {:ok, s} = Dwrr.enqueue(s, 0, [item(:served, 1), item(:retained, 2)])
    {:ok, [_], s} = Dwrr.take(s, 1)
    %{scheduler: s}
  end

  test "enqueue validates improper tails and malformed items after shared cost errors", %{
    scheduler: s
  } do
    for cost <- [0, @max_cost + 1],
        batch <- [
          [item(:rejected, cost) | :improper],
          [item(:rejected, cost), :malformed],
          [item(:rejected, cost), %{value: :not_a_struct, cost: 1}]
        ] do
      assert_raise ArgumentError, fn -> Dwrr.enqueue(s, 0, batch) end
    end

    assert_retained(s)
  end

  test "enqueue validates negative and noninteger later costs before shared errors", %{
    scheduler: s
  } do
    for first_cost <- [1, 0, @max_cost + 1],
        later_cost <- [-1, 1.0, 0.0, nil, "1"] do
      assert_raise ArgumentError, fn ->
        Dwrr.enqueue(s, 0, [item(:first, first_cost), item(:later, later_cost)])
      end
    end

    assert_retained(s)
  end

  test "enqueue validates all argument domains even with an invalid index", %{scheduler: s} do
    for index <- [-1, 1],
        batch <- [
          :not_a_list,
          [item(:zero, 0) | :improper],
          [:malformed],
          [item(:bad, -1)],
          [item(:bad, 1.0)]
        ] do
      assert_raise ArgumentError, fn -> Dwrr.enqueue(s, index, batch) end
    end

    for index <- [0.0, nil, "0"] do
      assert_raise ArgumentError, fn -> Dwrr.enqueue(s, index, []) end
    end

    assert_retained(s)
  end

  test "domain-valid enqueue preserves index-first and first-cost ordering atomically", %{
    scheduler: s
  } do
    for batch <- [[], [item(:zero, 0)], [item(:large, @max_cost + 1)]] do
      assert Dwrr.enqueue(s, -1, batch) == {:error, :invalid_index}
      assert Dwrr.enqueue(s, 1, batch) == {:error, :invalid_index}
    end

    assert Dwrr.enqueue(s, 0, [item(:valid, 1), item(:zero, 0), item(:large, @max_cost + 1)]) ==
             {:error, :zero_cost}

    assert Dwrr.enqueue(s, 0, [item(:valid, 1), item(:large, @max_cost + 1), item(:zero, 0)]) ==
             {:error, :cost_too_large}

    assert Dwrr.enqueue(s, 0, []) == {:ok, s}
    assert_retained(s)
  end

  test "set_quantum validates domains before invalid_index", %{scheduler: s} do
    for index <- [-1, 0, 1], quantum <- [-1, 0.0, 1.0, nil, "1"] do
      assert_raise ArgumentError, fn -> Dwrr.set_quantum(s, index, quantum) end
    end

    for index <- [0.0, nil, "0"], quantum <- [0, 1, @max_cost + 1] do
      assert_raise ArgumentError, fn -> Dwrr.set_quantum(s, index, quantum) end
    end

    assert_retained(s)
  end

  test "domain-valid set_quantum preserves shared ordering and active credit", %{scheduler: s} do
    for index <- [-1, 1], quantum <- [0, 1, @max_cost + 1] do
      assert Dwrr.set_quantum(s, index, quantum) == {:error, :invalid_index}
    end

    assert Dwrr.set_quantum(s, 0, 0) == {:error, :zero_quantum}
    assert Dwrr.set_quantum(s, 0, @max_cost + 1) == {:error, :quantum_too_large}
    assert {:ok, reweighted} = Dwrr.set_quantum(s, 0, @max_cost)
    assert reweighted == %{s | queues: Map.update!(s.queues, 0, &%{&1 | quantum: @max_cost})}
    assert_retained(s)
  end

  defp item(value, cost), do: %Dwrr.Item{value: value, cost: cost}

  defp assert_retained(s) do
    assert s.active
    assert s.queues[0].credit == 3
    assert {:ok, [%Dwrr.Item{value: :retained, cost: 2}], _} = Dwrr.drain_queue(s, 0)
    assert {:ok, [%Dwrr.Scheduled{queue: 0, value: :retained, cost: 2}], _} = Dwrr.take(s, 10)
  end
end
