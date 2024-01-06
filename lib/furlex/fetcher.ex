defmodule Furlex.Fetcher do
  @moduledoc """
  A module for fetching body data for a given url
  """
  use Tesla
  plug Tesla.Middleware.FollowRedirects, max_redirects: 3

  require Logger

  alias Furlex.Oembed

  @json_library Application.get_env(:furlex, :json_library, Jason)

  @doc """
  Fetches a url and extracts the body
  """
  @spec fetch(String.t(), List.t()) :: {:ok, String.t(), Integer.t()} | {:error, Atom.t()}
  def fetch(url, opts \\ []) do
    case URI.parse(url) do
      %URI{host: nil, path: nil} ->
        IO.warn("expected a valid URI, but got #{url}")
        {:error, :invalid_uri}

      %URI{scheme: nil, host: nil, path: host_detected_as_path} ->
        do_fetch("http://#{url}", opts)

      %URI{} ->
        do_fetch(url, opts)
    end
  end

  defp do_fetch(url, opts \\ []) do
    case get(url, opts) do
      {:ok, %{body: body, status: status_code}} -> {:ok, body, status_code}
      other                                     -> other
    end
  end


end
