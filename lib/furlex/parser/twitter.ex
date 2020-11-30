defmodule Furlex.Parser.Twitter do
  @behaviour Furlex.Parser

  alias Furlex.Parser

  @tags ~w(
    twitter:card twitter:site twitter:domain twitter:url twitter:site:id
    twitter:creator twitter:creator:id twitter:description twitter:title
    twitter:image twitter:image:alt twitter:player twitter:player:width
    twitter:player:height twitter:player:stream twitter:app:name:iphone
    twitter:app:id:iphone twitter:app:url:iphone twitter:app:name:ipad
    twitter:app:id:ipad twitter:app:url:ipad twitter:app:name:googleplay
    twitter:app:url:googleplay twitter:app:id:googleplay
  )

  @spec parse(String.t()) :: {:ok, Map.t()}
  def parse(html) do
    meta = &"meta[name=\"#{&1}\"]"
    map = Parser.extract(tags(), html, meta)

    {:ok, map}
  end

  @doc false
  def tags do
    (config(:tags) || [])
    |> Enum.concat(@tags)
    |> Enum.uniq()
  end

  defp config(key), do: Application.get_env(:furlex, __MODULE__)[key]
end
