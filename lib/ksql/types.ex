defmodule KSQL.Types do
  def to_ksql(_), do: nil

  def to_erl("BIGINT"), do: :integer
  def to_erl("STRING"), do: :string
  def to_erl("ARRAY"), do: :array
  def to_erl("MAP"), do: :map
  def to_erl(_), do: nil
end
