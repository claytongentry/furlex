defmodule Furlex.Oembed do
  @moduledoc """
  A module for managing oembed data
  """

  use GenServer

  require Logger

  @doc """
  Fetches the list of Oembed providers

  Soft fetch will fetch cached providers. Hard fetch requests
  providers from oembed.com and purges the cache.
  """
  @spec fetch_providers(Atom.t) :: {:ok, List.t} | {:error, Atom.t}
  def fetch_providers(type \\ :soft)
  def fetch_providers(:hard) do
    case HTTPoison.get("https://oembed.com/providers.json") do
      {:ok, %{body: body}} ->
        {:ok, providers} = Poison.decode(body)

        GenServer.cast __MODULE__, {:providers, providers}

        {:ok, providers}

      other                ->
        Logger.error "Could not fetch providers: #{inspect other}"

        {:error, :fetch_error}
    end
  end
  def fetch_providers(_type) do
    providers = GenServer.call __MODULE__, :providers

    if is_nil(providers) or length(providers) == 0 do
      fetch_providers(:hard)
    else
      {:ok, providers}
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
  @spec endpoint_from_url(String.t, Map.t) :: {:ok, String.t} | {:error, Atom.t}
  def endpoint_from_url(url, params \\ %{"format" => "json"}) do
    case provider_from_url(url) do
      nil      ->
        {:error, :no_oembed_provider}

      provider ->
        endpoint_from_provider(provider, params)
    end
  end

  # Maps a url to a provider, or returns nil if no such provider exists
  defp provider_from_url(url) do
    {:ok, providers} = fetch_providers()

    case URI.parse(url) do
      %URI{host: nil}  ->
        nil

      %URI{host: host} ->
        Enum.find providers, &host_matches?(host, &1)
    end
  end

  defp endpoint_from_provider(provider, params) do
    [ endpoint | _] = provider["endpoints"]

    url   = endpoint["url"]
    regex = ~r/{(.*?)}/
    url   = Regex.replace regex, url, fn _, key -> params[key] end

    {:ok, url}
  end

  defp host_matches?(host, %{"provider_url" => provider_url}) do
    Regex.match? ~r/https?:\/\/#{host}/, provider_url
  end

  ## GenServer callbacks

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([env: :test]) do
    {:ok, [
      %{
        "provider_name" => "Vimeo",
        "provider_url" => "https:\/\/vimeo.com\/",
        "endpoints" => [
          %{
            "url" => "https:\/\/vimeo.com/api/oembed.{format}",
            "discovery" => true
          }
        ]
      }
    ]}
  end
  def init(_) do
    case fetch_providers(:hard) do
      {:ok, providers} -> {:ok, providers}
      _                -> {:ok, []}
    end
  end

  def handle_call(:providers, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:providers, providers}, _) do
    {:noreply, providers}
  end
end
