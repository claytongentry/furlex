defmodule FurlexTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    url = "http://localhost:#{bypass.port}"

    oembed = Furlex.Oembed
    oembed_config = Application.get_env(:furlex, oembed, [])
    new_config = Keyword.put(oembed_config, :oembed_host, url)
    group_keys_config = Application.get_env(:furlex, :group_keys?)

    Application.put_env(:furlex, oembed, new_config)
    Application.put_env(:furlex, :group_keys?, true)

    on_exit(fn ->
      Application.put_env(:furlex, oembed, oembed_config)
      Application.put_env(:furlex, :group_keys?, group_keys_config)

      :ok
    end)

    {:ok, bypass: bypass, url: url}
  end

  test "unfurls a url", %{bypass: bypass, url: url} do
    Bypass.expect(bypass, &handle/1)

    assert {:ok, %Furlex{} = furlex} = Furlex.unfurl(url)

    assert furlex.status_code == 200
    assert furlex.facebook["og"]["site_name"] == "Vimeo"
    assert furlex.twitter["twitter"]["title"] == "FIDLAR - Cocaine (Feat. Nick Offerman)"
    assert Enum.at(furlex.json_ld, 0)["@type"] == "VideoObject"
  end

  def handle(%{request_path: "/providers.json"} = conn) do
    assert conn.method == "GET"

    providers =
      [__DIR__ | ~w(fixtures providers.json)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp(conn, 200, providers)
  end

  def handle(conn) do
    html =
      [__DIR__ | ~w(fixtures vimeo.html)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp(conn, 200, html)
  end
end
