defmodule Furlex.Parser.Twitter do
  @behaviour Furlex.Parser

  alias Furlex.Parser

  @spec parse(String.t) :: {:ok, Map.t}
  def parse(html) do
    tags = config(:tags)
    meta = &("meta[name=\"#{&1}\"]")

    map = Parser.extract tags, html, meta

    {:ok, map}
  end

  defp config(key), do: Application.get_env(:furlex, __MODULE__)[key]
end
