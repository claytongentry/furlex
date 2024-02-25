defmodule Furlex.Oembed do
  @moduledoc """
  A module for managing oembed data
  """

  use GenServer

  alias Furlex.Fetcher

  import Untangle
  use Arrows

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
        error(other, "Could not fetch oembed for: #{inspect(url)} - from endpoint: #{inspect detect_endpoint} - with error")

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
        error(other, "Could not find an oembed for #{inspect(url)}")

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
    with {:ok, body, 200} <- Fetcher.fetch(endpoint),
    {:ok, data} <- @json_library.decode(body) do 
      {:ok, %{oembed: data}}
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
          providers = prepare_providers_regexes(providers ++ config(:extra_providers))
          info(providers, "Caching oembed providers")
          GenServer.cast(__MODULE__, {:providers, providers})
          {:ok, providers}
        else error ->
          error(error, "Could not parse oembed providers")
          # {:error, :providers_parse_error}
          {:ok, prepare_providers_regexes(config(:extra_providers))}
        end

      other ->
        error(other, "Could not fetch oembed providers")
        # {:error, :providers_fetch_error}
        {:ok, prepare_providers_regexes(config(:extra_providers))}
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
        {:ok, endpoint_from_provider(provider, url, params) |> debug()}
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
      %URI{scheme: nil, host: nil, path: host_detected_as_path} when is_binary(host_detected_as_path) ->
        Enum.find(providers, &host_matches?(host_detected_as_path, &1))
        |> debug()

      %URI{host: host} when is_binary(host) ->
        Enum.find(providers, &host_matches?(host, &1))
        |> debug()

      _ ->
        nil
    end || Enum.find(providers, &an_endpoint_matches?(url, &1))
        |> debug()
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

  # defp host_matches?(host, %{"provider_url" => provider_url, "endpoints"=> endpoints}) when is_list(endpoints) do
  #   String.contains?(provider_url, host) or an_endpoint_matches?(host, endpoints)
  # end
  defp host_matches?(host, %{"provider_url" => provider_url}) do
    String.contains?(provider_url, host)
  end

  defp an_endpoint_matches?(url, %{"endpoints"=> endpoints}) when is_list(endpoints) do
    an_endpoint_matches?(url, endpoints)
  end
  defp an_endpoint_matches?(url, endpoints) when is_list(endpoints) do
    Enum.any?(endpoints, fn endpoint ->
      endpoint
      |> Map.get("schemes", []) 
      |> Enum.any?(fn 
        fun when is_function(fun, 1) -> fun.(url)
        |> debug(url)
        scheme -> 
        # with {:ok, regex} <- Regex.recompile(scheme) do
        #   Regex.match?(url, regex)
        #   |> debug("ran regex for provider")
        # else 
        #   e ->
        #     error(e, "Could not (re)compile regex for provider: #{scheme}")
            String.match?(url, scheme)
          # end
    end)
    end)
  end
  defp an_endpoint_matches?(url, _) do
    nil
  end

  defp prepare_providers_regexes(providers) when is_list(providers) or is_map(providers) do
    Enum.map(providers, &prepare_provider_regexes/1)
  end
  defp prepare_provider_regexes(%{"endpoints"=> endpoints}=provider) when is_list(endpoints) and endpoints !=[]  do
    Enum.map(endpoints, &prepare_endpoint_regexes/1)
    |> Map.put(provider, "endpoints", ...)
  end
  defp prepare_provider_regexes(provider) do
    provider
  end
  defp prepare_endpoint_regexes(%{"schemes"=> schemes}=endpoint) when is_list(schemes) and schemes !=[] do
    Enum.map(schemes, &prepare_scheme_regex/1)
    |> Map.put(endpoint, "schemes", ...)
  end
  defp prepare_endpoint_regexes(endpoint) do
    endpoint
  end
  defp prepare_scheme_regex(scheme) when is_binary(scheme) do
    with {:ok, regex} <- scheme
    |> String.replace("*", "[^/]+")
    |> String.replace(".", "\.")
    |> String.replace("http:", "#https?:")
    |> String.replace("https:", "#https?:")
    |> Regex.compile()
    |> debug(scheme) do
      regex
    else
      e -> 
        error(e)
        scheme
      end
  end
  defp prepare_scheme_regex(scheme) do
    scheme
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

  defp config(key) do
    :furlex
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key)
  end

  defp oembed_host do
    config(:oembed_host) || "https://oembed.com"
  end


end
