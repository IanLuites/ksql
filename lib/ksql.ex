defmodule KSQL do
  @moduledoc """
  Documentation for KSQL.
  """

  def stream!(stream) do
    with {:ok, data} <- stream(stream) do
      data
    else
      {:error, error} -> raise "StreamError: #{error}"
    end
  end

  def stream(stream) do
    with {:ok, events} <- query("SELECT * FROM #{stream.__resource__(:source)};") do
      {:ok,
       Stream.map(events, fn %{"row" => %{"columns" => data}} ->
         struct!(stream, :fields |> stream.__resource__() |> Enum.zip(data))
       end)}
    end
  end

  def query(query),
    do:
      if(String.starts_with?(query, "SELECT "), do: run_query(query), else: run_statement(query))

  ### Helpers ###
  # Move to different module

  defp run_query(query) do
    with {:ok, ref} <-
           HTTPX.request(
             :post,
             url("query"),
             body:
               Jason.encode!(%{
                 ksql: query,
                 streamsProperties: %{"ksql.streams.auto.offset.reset": "earliest"}
               }),
             headers: [
               {"Accept", "application/json"},
               {"Content-Type", "application/json"}
             ],
             format: :json_atoms,
             settings: [async: true]
           ) do
      setup_stream(ref)
    end
  end

  defp run_statement(query) do
    with {:ok, %{body: body}} <-
           HTTPX.request(
             :post,
             url("ksql"),
             body:
               Jason.encode!(%{
                 ksql: query,
                 streamsProperties: %{}
               }),
             headers: [
               {"Content-Type", "application/vnd.ksql.v1+json; charset=utf-8"}
             ],
             format: :json_atoms
           ) do
      result = Enum.map(body, &parse_response/1)

      if Enum.count(result) == 1 do
        {:ok, List.first(result)}
      else
        {:ok, result}
      end
    end
  end

  defp url(path), do: Application.get_env(:ksql, :url) <> path

  defp setup_stream(ref) do
    {status, data} =
      receive do
        {:hackney_response, ^ref, {:status, status, data}} -> {status, data}
      end

    headers =
      receive do
        {:hackney_response, ^ref, {:headers, headers}} -> headers
      end

    if status == 200 do
      {:ok, create_stream(ref)}
    else
      {:error, %{status: status, data: data, headers: headers}}
    end
  end

  defp create_stream(ref) do
    Stream.resource(
      fn -> ref end,
      fn ref ->
        receive do
          {:hackney_response, ^ref, :done} -> {:halt, ref}
          {:hackney_response, ^ref, "\n"} -> {[], ref}
          {:hackney_response, ^ref, data} -> {[Jason.decode!(data)], ref}
        end
      end,
      fn _ref -> :ok end
    )
  end

  defp parse_response(%{"@type": "streams", streams: streams}) do
    Enum.map(streams, &struct!(KSQL.Stream, &1))
  end

  defp parse_response(%{"@type": "tables", tables: tables}) do
    Enum.map(tables, &struct!(KSQL.Table, &1))
  end

  defp parse_response(a), do: a
end
