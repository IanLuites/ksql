defmodule KSQL.Query do
  defmacro __using__(_opts \\ []) do
    quote do
      require KSQL.Query
      import KSQL.Query
    end
  end

  defmacro from(a, opts) do
    stream =
      case a do
        {:in, _, [{_var, _, nil}, {:__aliases__, _, [stream]}]} -> Module.concat([stream])
        {:__aliases__, _, [stream]} -> Module.concat([stream])
      end

    {select_map, select_fields} =
      if fields = opts[:select] do
        f = parse_select_field(fields)
        {f, f |> Enum.map(&to_string/1) |> Enum.join(", ")}
      else
        {:unknown, "*"}
      end

    where =
      if w = opts[:where] do
        {op, _, [{{:., _, [{_var, _, nil}, field]}, _, []}, match]} = w
        op = if op == :==, do: :=, else: op
        " WHERE #{field} #{op} '#{match}'"
      else
        ""
      end

    quote do
      "SELECT #{unquote(select_fields)} FROM #{unquote(stream).__resource__(:source)}#{
        unquote(where)
      };"
      |> KSQL.query()
      |> elem(1)
      |> Stream.map(fn %{"row" => %{"columns" => data}} ->
        unquote(select_map) |> Enum.zip(data) |> Enum.into(%{})
      end)
    end
  end

  defp parse_select_field({:., _, [{_var, _, nil}, field]}) do
    [field]
  end

  defp parse_select_field(fields) when is_tuple(fields) do
    fields |> Tuple.to_list() |> Enum.flat_map(&parse_select_field/1)
  end

  defp parse_select_field(_), do: []
end
