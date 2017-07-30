defmodule Furlex.Fetcher do
  @moduledoc """
  A module for fetching body data for a given url
  """

  require Logger

  alias Furlex.Oembed

  @doc """
  Fetches a url and extracts the body
  """
  def fetch(url) do
    case HTTPoison.get(url) do
      {:ok, %{body: body}} -> {:ok, body}
      other                -> other
    end
  end

  @doc """
  Fetches oembed data for the given url
  """
  def fetch_oembed(url, params \\ %{"format" => "json"}) do
    with {:ok, endpoint} <- Oembed.endpoint_from_url(url, params),
         params          = Map.merge(params, %{url: url}),
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
