defmodule Furlex.OembedTest do
  use ExUnit.Case

  alias Furlex.Oembed

  doctest Oembed

  setup do
    bypass = Bypass.open()
    url    = "http://localhost:#{bypass.port}"
    config = Application.get_env :furlex, Oembed

    Application.put_env :furlex, Oembed, [oembed_host: url]

    on_exit fn ->
      Application.put_env :furlex, Oembed, config

      :ok
    end

    {:ok, bypass: bypass}
  end

  test "returns endpoint from url", %{bypass: bypass} do
    Bypass.expect bypass, &handle/1

    assert {:error, :no_oembed_provider} ==
      Oembed.endpoint_from_url("foobar")

    url    = "https://vimeo.com/88856141"
    params = %{"format" => "json"}

    {:ok, endpoint} = Oembed.endpoint_from_url(url, params)

    assert endpoint == "https://vimeo.com/api/oembed.json"
  end

  def handle(%{request_path: "/providers.json"} = conn) do
    assert conn.method == "GET"

    providers =
      [__DIR__ | ~w(.. fixtures providers.json)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp conn, 200, providers
  end
end
