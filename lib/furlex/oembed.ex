defmodule Furlex.Oembed do
  @moduledoc """
  A module for managing oembed data
  """

  use GenServer

  alias Furlex.Fetcher

  require Logger

  @json_library Application.get_env(:furlex, :json_library, Jason)

  @doc """
  Fetches the list of Oembed providers

  Soft fetch will fetch cached providers. Hard fetch requests
  providers from oembed.com and purges the cache.
  """
  @spec fetch_providers(Atom.t()) :: {:ok, List.t()} | {:error, Atom.t()}
  def fetch_providers(type \\ :soft)

  def fetch_providers(:hard) do
    case Fetcher.fetch("https://oembed.com/providers.json") do
      {:ok, providers, 200} ->

        with {:ok, providers} <- Jason.decode(providers) do
          GenServer.cast(__MODULE__, {:providers, providers})
          {:ok, providers}
        else error ->
          Logger.error("Could not parse providers: #{inspect(error)}")
          {:error, :providers_parse_error}
        end

      other ->
        Logger.error("Could not fetch providers: #{inspect(other)}")
        {:error, :providers_fetch_error}
    end
  end

  def fetch_providers(_soft) do
    case GenServer.call(__MODULE__, :providers) do
      nil -> fetch_providers(:hard)
      providers -> {:ok, providers}
    end
  end

  @doc """
  Returns an Oembed endpoint for the given url

  ## Examples

    iex> Oembed.endpoint_from_url "https://vimeo.com/88856141"
    {:ok, "https://vimeo.com/api/oembed.json"}

    iex> Oembed.endpoint_from_url "https://vimeo.com/88856141", %{"format" => "xml"}
    {:ok, "https://vimeo.com/api/oembed.xml"}
  """
  @spec endpoint_from_url(String.t(), Map.t()) :: {:ok, String.t()} | {:error, Atom.t()}
  def endpoint_from_url(url, params \\ %{"format" => "json"}, opts \\ []) do
    case provider_from_url(url, opts) do
      nil ->
        {:error, :no_oembed_provider}

      provider ->
        endpoint_from_provider(provider, params)
    end
  end

  def endpoint_from_html(html) do
    case parse_html_for_oembed(html) do
      {_, provider} ->
        {:ok, provider}
      _ ->
        {:error, :no_oembed_provider}
    end
  end

  defp parse_html_for_oembed(html) do
    doc = html
    |> Floki.parse_document()
    |> elem(1)

    (Furlex.Parser.extract("application/json+oembed", doc, &"link[type=\"#{&1}\"]", "href") || Furlex.Parser.extract("text/xml+oembed", doc, &"link[type=\"#{&1}\"]", "href"))
  end

  # Maps a url to a provider, or returns nil if no such provider exists
  defp provider_from_url(url, opts) do
    fetch_type = if Keyword.get(opts, :skip_cache?, false), do: :hard, else: :soft

    {:ok, providers} = fetch_providers(fetch_type)

    case URI.parse(url) do
      %URI{host: nil} ->
        nil

      %URI{host: host} ->
        Enum.find(providers, &host_matches?(host, &1))
    end
  end

  defp endpoint_from_provider(provider, params) do
    [endpoint | _] = provider["endpoints"]

    url = endpoint["url"]
    regex = ~r/{(.*?)}/
    url = Regex.replace(regex, url, fn _, key -> params[key] end)

    {:ok, url}
  end

  defp host_matches?(host, %{"provider_url" => provider_url}) do
    String.contains?(provider_url, host)
  end

  ## GenServer callbacks

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:providers, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:providers, providers}, _) do
    {:noreply, providers}
  end

  def process_url(path) do
    oembed_host() <> path
  end

  def process_response_body(body) do
    case @json_library.decode(body) do
      {:ok, body} -> body
      _error -> body
    end
  end

  defp config(key) do
    :furlex
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key)
  end

  defp oembed_host do
    config(:oembed_host) || "https://oembed.com"
  end


end
