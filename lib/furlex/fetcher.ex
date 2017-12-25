defmodule Furlex.Fetcher do
  @moduledoc """
  A module for fetching body data for a given url
  """

  require Logger

  alias Furlex.Oembed

  @doc """
  Fetches a url and extracts the body
  """
  @spec fetch(String.t, List.t) :: {:ok, String.t, Integer.t} | {:error, Atom.t}
  def fetch(url, opts \\ []) do
    case HTTPoison.get(url, [], opts) do
      {:ok, %{body: body, status_code: status_code}} -> {:ok, body, status_code}
      other                                          -> other
    end
  end

  @doc """
  Fetches oembed data for the given url
  """
  @spec fetch_oembed(String.t, List.t) :: {:ok, String.t} | {:ok, nil} | {:error, Atom.t}
  def fetch_oembed(url, opts \\ []) do
    with {:ok, endpoint} <- Oembed.endpoint_from_url(url),
         params           = %{"url" => url},
         opts             = Keyword.put(opts, :params, params),
         {:ok, response} <- HTTPoison.get(endpoint, [], opts),
         {:ok, body}     <- Poison.decode(response.body)
    do
      {:ok, body}
    else
      {:error, :no_oembed_provider} ->
        {:ok, nil}

      other ->
        "Could not fetch oembed for #{inspect url}: #{inspect other}"
        |> Logger.error()

        {:ok, nil}
    end
  end
end
