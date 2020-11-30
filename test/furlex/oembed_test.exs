defmodule Furlex.OembedTest do
  use ExUnit.Case

  alias Furlex.Oembed

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"
    config = Application.get_env(:furlex, Oembed, [])

    new_config = Keyword.put(config, :oembed_host, url)
    Application.put_env(:furlex, Oembed, new_config)

    on_exit(fn ->
      Application.put_env(:furlex, Oembed, config)

      :ok
    end)

    {:ok, bypass: bypass}
  end

  test "returns endpoint from url", %{bypass: bypass} do
    Bypass.expect(bypass, &handle/1)

    assert {:error, :no_oembed_provider} ==
             Oembed.endpoint_from_url("foobar")

    url = "https://vimeo.com/88856141"
    params = %{"format" => "json"}

    {:ok, endpoint} = Oembed.endpoint_from_url(url, params, skip_cache?: true)

    assert endpoint == "https://vimeo.com/api/oembed.json"
  end

  test "returns endpoint from url with subdomain", %{bypass: bypass} do
    Bypass.expect(bypass, &handle/1)

    assert {:error, :no_oembed_provider} ==
             Oembed.endpoint_from_url("foobar")

    url = "https://twitter.com/arshia__/status/1204481088422178817?s=20"
    params = %{"format" => "json"}

    {:ok, endpoint} = Oembed.endpoint_from_url(url, params, skip_cache?: true)

    assert endpoint == "https://publish.twitter.com/oembed"
  end

  def handle(%{request_path: "/providers.json"} = conn) do
    assert conn.method == "GET"

    providers =
      [__DIR__ | ~w(.. fixtures providers.json)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp(conn, 200, providers)
  end
end
