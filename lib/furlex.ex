defmodule Furlex do
  @moduledoc """
  Furlex is a structured data extraction tool written in Elixir.

  It currently supports unfurling oEmbed, Twitter Card, Facebook Open Graph,
  JSON-LD and plain ole' HTML `<meta />` data out of any url you supply.
  """

  use Application

  alias Furlex.{Fetcher, Parser}
  alias Furlex.Parser.{Facebook, HTML, JsonLD, Twitter}

  defstruct [
    :canonical_url,
    :oembed,
    :facebook,
    :twitter,
    :json_ld,
    :other,
    :status_code
  ]

  @type t :: %__MODULE__{
          canonical_url: String.t(),
          oembed: nil | Map.t(),
          facebook: Map.t(),
          twitter: Map.t(),
          json_ld: List.t(),
          other: Map.t(),
          status_code: Integer.t()
        }

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    opts = [strategy: :one_for_one, name: Furlex.Supervisor]

    children = [
      worker(Furlex.Oembed, [[name: Furlex.Oembed]])
    ]

    Supervisor.start_link(children, opts)
  end

  @doc """
  Unfurls a url

  unfurl/1 fetches oembed data if applicable to the given url's host,
  in addition to Twitter Card, Open Graph, JSON-LD and other HTML meta tags.

  unfurl/2 also accepts a keyword list that will be passed to HTTPoison.
  """
  @spec unfurl(String.t(), Keyword.t()) :: {:ok, __MODULE__.t()} | {:error, Atom.t()}
  def unfurl(url, opts \\ []) do
    with {:ok, {body, status_code}, oembed} <- fetch(url, opts),
         {:ok, results} <- parse(body) do
      {:ok,
       %__MODULE__{
         canonical_url: Parser.extract_canonical(body),
         oembed: oembed,
         facebook: results.facebook,
         twitter: results.twitter,
         json_ld: results.json_ld,
         other: results.other,
         status_code: status_code
       }}
    end
  end

  defp fetch(url, opts) do
    fetch = Task.async(Fetcher, :fetch, [url, opts])
    fetch_oembed = Task.async(Fetcher, :fetch_oembed, [url, opts])
    yield = Task.yield_many([fetch, fetch_oembed])

    with [fetch, fetch_oembed] <- yield,
         {_fetch, {:ok, {:ok, body, status_code}}} <- fetch,
         {_fetch_oembed, {:ok, {:ok, oembed}}} <- fetch_oembed do
      {:ok, {body, status_code}, oembed}
    else
      _ -> {:error, :fetch_error}
    end
  end

  defp parse(body) do
    parse = &Task.async(&1, :parse, [body])
    tasks = Enum.map([Facebook, Twitter, JsonLD, HTML], parse)

    with [facebook, twitter, json_ld, other] <- Task.yield_many(tasks),
         {_facebook, {:ok, {:ok, facebook}}} <- facebook,
         {_twitter, {:ok, {:ok, twitter}}} <- twitter,
         {_json_ld, {:ok, {:ok, json_ld}}} <- json_ld,
         {_other, {:ok, {:ok, other}}} <- other do
      {:ok,
       %{
         facebook: facebook,
         twitter: twitter,
         json_ld: json_ld,
         other: other
       }}
    else
      _ -> {:error, :parse_error}
    end
  end
end
