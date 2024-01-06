defmodule Furlex.Oembed do
  @moduledoc """
  A module for managing oembed data
  """

  use GenServer

  alias Furlex.Fetcher

  require Logger

  @json_library Application.get_env(:furlex, :json_library, Jason)

  @doc """
  Fetches oembed data for the given url *if* it comes from a known provider
  """
  @spec fetch(String.t(), List.t()) :: {:ok, String.t()} | {:ok, nil} | {:error, Atom.t()}
  def fetch(url, opts \\ []) do
    detect_endpoint = endpoint_from_url(url)
    with {:ok, endpoint} <- detect_endpoint,
         {:ok, data}     <- do_fetch_from_endpoint(endpoint, url)
    do
      {:ok, data}
    else
      {:error, :no_oembed_provider} ->
        {:ok, nil}

      other ->
        "Could not fetch oembed for #{inspect(url)} from #{inspect detect_endpoint}: #{inspect(other)}"
        |> Logger.error()

        {:ok, nil}
    end
  end

  @doc """
  Looks for an oembed link in the HTML of the given url and fetches it
  """
  def detect_and_fetch(url, html, opts \\ []) do
    with {:ok, endpoint} <- endpoint_from_html(html),
         {:ok, data}     <- do_fetch_from_endpoint(endpoint, url)
    do
      data
    else
      {:error, :no_oembed_provider} ->
        nil

      other ->
        "Could not find an oembed for #{inspect(url)}: #{inspect(other)}"
        |> Logger.error()

        nil
    end
  end

  defp do_fetch_from_endpoint({mod, fun}, url) when is_atom(mod) and is_atom(fun) do
    apply(mod, fun, [url])
  end
  defp do_fetch_from_endpoint(fun, url) when is_function(fun) do
    fun.(url)
  end
  defp do_fetch_from_endpoint(endpoint, _url) do
    with {:ok, body, 200} <- Fetcher.fetch(endpoint) do 
      @json_library.decode(body)
    end
  end

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
          providers = config(:extra_providers) ++ providers
          Logger.info("Caching oembed providers: #{inspect(providers)}")
          GenServer.cast(__MODULE__, {:providers, providers})
          {:ok, providers}
        else error ->
          Logger.error("Could not parse oembed providers: #{inspect(error)}")
          {:error, :providers_parse_error}
        end

      other ->
        Logger.error("Could not fetch oembed providers: #{inspect(other)}")
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
        {:ok, endpoint_from_provider(provider, url, params) |> IO.inspect}
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
      %URI{host: nil, path: nil} ->
        nil

      %URI{scheme: nil, host: nil, path: host_detected_as_path} ->
        Enum.find(providers, &host_matches?(host_detected_as_path, &1))

      %URI{host: host} ->
        Enum.find(providers, &host_matches?(host, &1))
    end
  end

  defp endpoint_from_provider(%{"fetch_function" => fetch_function} = _provider, url, _params) when is_function(fetch_function) do
    fetch_function
  end
  defp endpoint_from_provider(%{"fetch_function" => {mod, fun}} = _provider, url, _params) do
    {mod, fun}
  end
  defp endpoint_from_provider(%{"endpoints" => endpoints} = _provider, url, params) do
    [endpoint | _] = endpoints
    # TODO: support multiple endpoints?

    endpoint_url = Regex.replace(~r/{(.*?)}/, endpoint["url"], fn _, key -> params[key] end)

    if endpoint["append_url"] do 
      "#{endpoint_url}#{url}"
    else
      URI.append_query(URI.parse(endpoint_url), URI.encode_query(%{"url" => url}))
    end
  end

  defp host_matches?(host, %{"provider_url" => provider_url, "endpoints"=> endpoints}) when is_list(endpoints) do
    String.contains?(provider_url, host) or an_endpoint_matches?(host, endpoints)
  end
  defp host_matches?(host, %{"provider_url" => provider_url}) do
    String.contains?(provider_url, host)
  end
  defp host_matches?(host, %{"endpoints"=> endpoints}) when is_list(endpoints) do
    an_endpoint_matches?(host, endpoints)
  end

  defp an_endpoint_matches?(host, endpoints) do
    Enum.any?(endpoints, fn endpoint ->

      endpoint
      |> Map.get("schemes", []) 
      |> Enum.any?(fn scheme -> 
        String.contains?(scheme, host)
    end)
      
    end)
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
