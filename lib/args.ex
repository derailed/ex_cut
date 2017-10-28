defmodule ExCut.Args do
  @moduledoc false

  @doc """
  Ensures that all ignored arguments are
  expanded when calling the cross-cutting function.
  """
  def expand(args) do
    args
    |> Enum.map(fn(arg) ->
      arg
      |> case do
        {:%{}, l, m}         -> {:%{}, l, m |> expand}
        [{k, {a, l, m}} | t] -> [{k, {a |> unignore, l, m}} | t |> expand]
        {k, {a, l, m}}       -> {k, {a |> unignore, l, m}}
        {a, l, m}            -> {a |> unignore, l, m}
      end
    end)
  end

  defp unignore(arg) do
    a = arg |> Atom.to_string()

    a
    |> String.starts_with?("_")
    |> case do
      true  -> a |> String.replace_leading("_", "") |> String.to_atom
      false -> arg
    end
  end
end
