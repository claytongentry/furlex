defmodule Furlex.OembedTest do
  use ExUnit.Case

  alias Furlex.Oembed

  doctest Oembed

  setup do
    bypass = Bypass.open()
    url    = "http://localhost:#{bypass.port}"
    config = Application.get_env :furlex, Oembed

    Application.put_env :furlex, Oembed, [host: url]

    on_exit fn ->
      Application.put_env :furlex, Oembed, config

      :ok
    end

    {:ok, bypass: bypass}
  end

  test "returns endpoint from url" do
    assert {:error, :no_oembed_provider}          ==
      Oembed.endpoint_from_url("foobar")

    assert {:ok, "http://www.23hq.com/23/oembed"} ==
      Oembed.endpoint_from_url("http://www.23hq.com/Spelterini/photo/33636190")
  end

  def handle(%{request_path: "/providers.json"} = conn) do
    providers =
      [__DIR__ | ~w(.. fixtures providers.json)]
      |> Path.join()
      |> File.read!()

    Plug.Conn.resp conn, 200, providers
  end
end
