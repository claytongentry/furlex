defmodule Furlex do
  @moduledoc """
  Furlex is a structured data extraction tool written in Elixir.

  It currently supports unfurling oEmbed, Twitter Card, Facebook Open Graph,
  JSON-LD and plain ole' HTML `<meta />` data out of any url you supply.
  """

  use Application
  import Untangle

  alias Furlex.{Fetcher, Parser, Oembed}
  alias Furlex.Parser.{Facebook, HTML, JsonLD, Twitter, RelMe}

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
  @spec unfurl(String.t(), Keyword.t()) :: {:ok, Map.t()} | {:error, Atom.t()}
  def unfurl(url, opts \\ []) do
    case fetch(url, opts) 
          |> debug() do
     {:ok, {body, status_code}, oembed_meta} when is_binary(body) ->
      unfurl_html(url, body, Enum.into(oembed_meta || %{}, %{
        status_code: status_code
       }), opts)

      other -> 
        error(other, "Could not fetch any metadata")
    end
  end

  def unfurl_html(url, body, extra, opts \\ []) do
    with {:ok, body} <- Floki.parse_document(body),
        canonical_url <- Parser.extract_canonical(body),
         {:ok, results} <- parse(
          body, 
          opts #++ [urls: [url, canonical_url]]
         ) do
      {:ok,
      extra
      |> Map.merge(results || %{})
      |> Map.merge(%{
         canonical_url: (if canonical_url !=url, do: canonical_url),
         favicon: maybe_favicon(url, body)
       })}
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

  defp parse(body, opts) do
    parse = &Task.async(&1, :parse, [body, opts])
    tasks = Enum.map([Facebook, Twitter, JsonLD, RelMe, HTML], parse)

    with [facebook, twitter, json_ld, rel_me, other] <- Task.yield_many(tasks),
         {_facebook, {:ok, {:ok, facebook}}} <- facebook,
         {_twitter, {:ok, {:ok, twitter}}} <- twitter,
         {_json_ld, {:ok, {:ok, json_ld}}} <- json_ld,
         {_rel_me, {:ok, {:ok, rel_me}}} <- rel_me,
         {_other, {:ok, {:ok, other}}} <- other do
      {:ok,
       %{
         facebook: facebook,
         twitter: twitter,
         json_ld: json_ld,
         other: other,
         rel_me: rel_me
       }}
    else
      _ -> {:error, :parse_error}
    end
  end

  def maybe_favicon(url, body) do
    if Code.ensure_loaded?(FetchFavicon) do
    case URI.parse(url) |> debug() do
      # %URI{host: nil, path: nil} ->
      %URI{host: nil} ->
        warn(url, "expected a valid URI, but got")
        debug(body)
        with true <- body !=[],
        {:ok, url} <- FetchFavicon.find(nil, body) do
          url
        else _ ->
          nil
        end

      # %URI{scheme: nil, host: nil, path: host_detected_as_path} ->
      #   with {:ok, url} <- FetchFavicon.find(host_detected_as_path, body) do
      #   url
      # else _ ->
      #   nil
      # end

      %URI{scheme: "doi"} ->
        nil

      %URI{} ->
        FetchFavicon.find(url, body)


    end

      
    end

  end

end
