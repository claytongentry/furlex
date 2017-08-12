defmodule Furlex.Parser.Facebook do
  @behaviour Furlex.Parser

  alias Furlex.Parser

  @tags ~w(
    fb:app_id fb:pages

    og:url og:title og:description og:image og:type og:locale og:video
    og:video:url og:video:secure_url og:video:type og:video:width
    og:video:height og:image:url og:image:secure_url og:image:type
    og:image:width og:image:height og:audio og:determiner og:locale:alternate
    og:site_name og:image:alt

    article:published_time article:modified_time
    article:expiration_time article:author article:section article:tag

    book:author book:isbn book:release_date book:tag

    profile:first_name profile:last_name profile:username profile:gender

    music:duration music:album music:album:disc music:album:track
    music:musician music:song music:song:disc music:song:track
    music:release_date music:creator

    video:actor video:actor:role video:director video:duration
    video:release_date video:tag video:writer video:series
  )

  @spec parse(String.t) :: {:ok, Map.t}
  def parse(html) do
    meta = &("meta[property=\"#{&1}\"]")
    map  = Parser.extract tags(), html, meta

    {:ok, map}
  end

  def tags do
    (config(:tags) || [])
    |> Enum.concat(@tags)
    |> Enum.uniq()
  end

  defp config(key), do: Application.get_env(:furlex, __MODULE__)[key]
end
