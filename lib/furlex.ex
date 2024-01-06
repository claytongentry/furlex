defmodule Furlex do
  @moduledoc """
  Furlex is a structured data extraction tool written in Elixir.

  It currently supports unfurling oEmbed, Twitter Card, Facebook Open Graph,
  JSON-LD and plain ole' HTML `<meta />` data out of any url you supply.
  """

  use Application

  alias Furlex.{Fetcher, Parser, Oembed}
  alias Furlex.Parser.{Facebook, HTML, JsonLD, Twitter}

  defstruct [
    :canonical_url,
    :favicon,
    :oembed,
    :facebook,
    :twitter,
    :json_ld,
    :other,
    :status_code
  ]

  @type t :: %__MODULE__{
          canonical_url: String.t(),
          favicon: String.t(),
          oembed: nil | Map.t(),
          facebook: Map.t(),
          twitter: Map.t(),
          json_ld: List.t(),
          other: Map.t(),
          status_code: Integer.t()
        }

  @doc false
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Furlex.Supervisor]

    children = [
      Furlex.Oembed
    ]

    Supervisor.start_link(children, opts)
  end

  @doc """
  Unfurls a url

  unfurl/1 fetches oembed data if applicable to the given url's host,
  in addition to Twitter Card, Open Graph, JSON-LD and other HTML meta tags.

  unfurl/2 also accepts opts as a keyword list that will be passed to the fetcher.
  """
  @spec unfurl(String.t(), Keyword.t()) :: {:ok, __MODULE__.t()} | {:error, Atom.t()}
  def unfurl(url, opts \\ []) do
    with {:ok, {body, status_code}, oembed} <- fetch(url, opts),
         {:ok, body} <- Floki.parse_document(body),
         {:ok, results} <- parse(body),
         canonical_url <- Parser.extract_canonical(body) do
      {:ok,
       %__MODULE__{
         canonical_url: (if canonical_url !=url, do: canonical_url),
         favicon: maybe_favicon(url, body),
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
    fetch_oembed = Task.async(Oembed, :fetch, [url, opts])
    fetch = Task.async(Fetcher, :fetch, [url, opts])

    with [fetch_oembed, fetch] <- Task.yield_many([fetch_oembed, fetch], timeout: 4000, on_timeout: :kill_task) do
      case [fetch_oembed, fetch] do
        [{_fetch_oembed, {:ok, {:ok, oembed}}}, {_fetch, {:ok, {:ok, body, status_code}}}] ->

        {:ok, {body, status_code}, oembed || Oembed.detect_and_fetch(url, body, opts)} # if no oembed was found from a known provider, try via the HTML

      [{_fetch_oembed, {:ok, {:ok, oembed}}}, other] ->
        IO.warn(inspect other)
        {:ok, {nil, nil}, oembed} #  oembed was found from a known provider

      [other, {_fetch, {:ok, {:ok, body, status_code}}}] ->
        IO.warn(inspect other)
        {:ok, {body, status_code}, Oembed.detect_and_fetch(url, body, opts)} # if no oembed was found from a known provider, try via the HTML

      [other, other2] ->
        IO.warn(inspect other)
        IO.warn(inspect other2)
        {:error, :fetch_error}

      end
    else
      other -> 
        IO.warn(inspect other)
        {:error, :fetch_error}
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

  def maybe_favicon(url, body) do
    if Code.ensure_loaded?(FetchFavicon) do
      with {:ok, url} <-  FetchFavicon.find(url, body) do
        url
      else _ ->
        nil
      end
    end

  end

end
