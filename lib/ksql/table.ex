defmodule KSQL.Table do
  @enforce_keys ~w(
    format
    isWindowed
    name
    topic
    type
  )a
  defstruct @enforce_keys

  defmacro __using__(_opts \\ []) do
    quote do
      import KSQL.Table, only: [stream: 2]
    end
  end

  defmacro field(name, _type) do
    quote do
      Module.put_attribute(__MODULE__, :table_fields, unquote(name))
    end
  end

  defmacro stream(stream, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :table_fields, accumulate: true)

      try do
        import KSQL.Table, only: [field: 2]
        unquote(block)
      after
        :ok
      end

      @struct_fields Enum.reverse(@table_fields)
      defstruct @struct_fields

      @doc false
      def __stream__(:source), do: unquote(to_string(elem(stream, 0)))
      def __stream__(:fields), do: Enum.reverse(@struct_fields)
    end
  end

  def to_module(%{name: stream}), do: to_module(stream)

  def to_module(stream) do
    fields =
      "DESCRIBE #{stream};"
      |> KSQL.query()
      |> Map.get(:sourceDescription)
      |> Map.get(:fields)
      |> Enum.map(fn %{name: name, schema: %{fields: _, memberSchema: _, type: type}} ->
        "    field :" <> String.downcase(name) <> ", " <> inspect(KSQL.Types.to_erl(type))
      end)
      |> Enum.join("\n")

    """
    defmodule #{Macro.camelize(String.downcase(stream))} do
      use KSQL.Table

      stream #{String.downcase(stream)} do
    #{fields}
      end
    end
    """
  end
end
