# Complete; do not change.
Code.require_file("../support/stage2_assets_helper.exs", __DIR__)

defmodule Dwrr.Stage2.PublicDocsTest do
  use ExUnit.Case, async: false
  import Dwrr.Stage2Support

  test "stage1 public executable AST and representation remain unchanged" do
    for {path, expected} <- JSON.decode!(File.read!("test/fixtures/stage1-preserved-sha256.json")) do
      actual = :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
      assert actual == expected, "stage1 complete file changed: #{path}"
    end

    # The sole authorized stage-1 helper overlay is not an unchanged-file claim.
    overlay = JSON.decode!(File.read!("test/fixtures/stage2-helper-overlay-sha256.json"))

    helper_hash =
      :crypto.hash(:sha256, File.read!(overlay["path"])) |> Base.encode16(case: :lower)

    assert helper_hash == overlay["sha256"]

    ast = Code.string_to_quoted!(File.read!("lib/dwrr.ex"))
    assert Dwrr.PublicContract.executable(ast) == Dwrr.PublicContract.stage1_ast()
  end

  test "all public operations have typespecs with the appropriate arities and no any return" do
    {:ok, specs} = Code.Typespec.fetch_specs(Dwrr)

    wanted = [
      new: 1,
      enqueue: 3,
      take: 2,
      set_quantum: 3,
      add_queue: 1,
      remove_queue: 1,
      remove_head: 2,
      drain_queue: 2
    ]

    assert Enum.sort(Enum.map(specs, &elem(&1, 0))) == Enum.sort(wanted)

    expected =
      JSON.decode!(File.read!("test/fixtures/stage2-spec-signatures.json"))
      |> Enum.map(&(Code.string_to_quoted!(&1) |> Macro.to_string()))
      |> Enum.sort()

    actual =
      Enum.map(specs, fn {{name, _}, [clause]} ->
        Code.Typespec.spec_to_quoted(name, clause) |> Macro.to_string()
      end)
      |> Enum.sort()

    assert actual == expected

    {:ok, server_specs} = Code.Typespec.fetch_specs(Dwrr.Server)

    server_expected =
      JSON.decode!(File.read!("test/fixtures/stage2-server-spec-signatures.json"))
      |> Enum.map(&(Code.string_to_quoted!(&1) |> Macro.to_string()))
      |> Enum.sort()

    server_actual =
      Enum.filter(server_specs, fn {{name, _}, _} -> name != :child_spec end)
      |> Enum.map(fn {{name, _}, [clause]} ->
        Code.Typespec.spec_to_quoted(name, clause) |> Macro.to_string()
      end)
      |> Enum.sort()

    assert server_actual == server_expected

    for {{name, arity}, clauses} <- specs do
      assert length(clauses) == 1

      source =
        clauses |> hd() |> then(&Code.Typespec.spec_to_quoted(name, &1)) |> Macro.to_string()

      refute source =~ "any()", "#{name}/#{arity}: meaningless type"
      assert source =~ "t(", "#{name}/#{arity}: scheduler type missing"
    end
  end

  test "public module docs describe exact failures and execute branching/error examples" do
    {:docs_v1, _, _, _, %{"en" => docs}, _, entries} = Code.fetch_docs(Dwrr)
    assert String.contains?(docs, "ArgumentError")
    assert String.contains?(docs, "2^63-1")
    assert String.contains?(docs, "immutable")

    for {{:function, name, arity}, _, _, doc, _} <- entries, name != :__struct__ do
      assert is_map(doc), "#{name}/#{arity} needs docs"
    end

    # Same extractor as README, executed with genuinely asserted result values.
    path = Path.join(System.tmp_dir!(), "dwrr-docs-#{System.unique_integer([:positive])}.md")
    File.write!(path, docs)

    try do
      eval_examples(path, [[:job], {[:original], [:original]}, {:error, :zero_cost}])
    after
      File.rm!(path)
    end
  end
end
