# Complete; do not change. Captured stage-1 AST; only docs/typespec additions are editable.
defmodule Dwrr.PublicContract do
  def executable(ast) do
    Macro.prewalk(ast, fn
      {:@, _, [{name, _, _}]} when name in [:doc, :moduledoc, :spec] -> nil
      {form, meta, args} when is_list(meta) -> {form, Keyword.drop(meta, [:line, :column]), args}
      node -> node
    end)
    |> Macro.postwalk(fn
      {:__block__, meta, args} -> {:__block__, meta, Enum.reject(args, &is_nil/1)}
      node -> node
    end)
  end

  def stage1_ast do
    Code.string_to_quoted!(File.read!(Path.expand("../fixtures/stage1_dwrr.ex.txt", __DIR__)))
    |> executable()
  end
end
