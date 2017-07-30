defmodule FurlexTest do
  use ExUnit.Case

  doctest Furlex

  setup do
    bypass = Bypass.open()
    url    = "http://localhost:#{bypass.port}"

    {:ok, bypass: bypass, url: url}
  end

  test "unfurls a url", %{bypass: bypass, url: url} do
    Bypass.expect bypass, &handle/1

    assert {:ok, %Furlex{} = furlex} = Furlex.unfurl(url)

    assert furlex.facebook["og:site_name"]     == "Vimeo"
    assert furlex.twitter["twitter:title"]     == "FIDLAR - Cocaine (Feat. Nick Offerman)"
    assert Enum.at(furlex.json_ld, 0)["@type"] == "VideoObject"
  end

  def handle(conn) do
    html =
      [__DIR__ | ~w(fixtures vimeo.html)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp conn, 200, html
  end
end
