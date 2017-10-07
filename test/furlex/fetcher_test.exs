defmodule Furlex.FetcherTest do
  use ExUnit.Case

  alias Furlex.Fetcher

  doctest Fetcher

  setup do
    bypass = Bypass.open()
    url    = "http://localhost:#{bypass.port}"

    {:ok, bypass: bypass, url: url}
  end

  test "fetches url", %{bypass: bypass, url: url} do
    Bypass.expect_once bypass, &handle/1

    assert {:ok, body, 200} = Fetcher.fetch(url)
    assert body             =~ "<title>Test HTML</title>"
  end

  def handle(conn) do
    body =
      [__DIR__ | ~w(.. fixtures test.html)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp conn, 200, body
  end
end
