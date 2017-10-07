defmodule Furlex.Fetcher do
  @moduledoc """
  A module for fetching body data for a given url
  """

  require Logger

  alias Furlex.Oembed

  @doc """
  Fetches a url and extracts the body
  """
  @spec fetch(String.t) :: {:ok, String.t} | {:error, Atom.t}
  def fetch(url) do
    case HTTPoison.get(url) do
      {:ok, %{body: body, status_code: status_code}} -> {:ok, body, status_code}
      other                                          -> other
    end
  end

  @doc """
  Fetches oembed data for the given url
  """
  @spec fetch_oembed(String.t) :: {:ok, String.t} | {:ok, nil} | {:error, Atom.t}
  def fetch_oembed(url) do
    with {:ok, endpoint} <- Oembed.endpoint_from_url(url),
         params           = %{"url" => url},
         {:ok, response} <- HTTPoison.get(endpoint, [], params: params),
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
