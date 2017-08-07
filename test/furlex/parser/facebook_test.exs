defmodule Furlex.Parser.FacebookTest do
  use ExUnit.Case

  alias Furlex.Parser.Facebook

  doctest Facebook

  test "parses Facebook Open Graph" do
    html = "<html><head><meta property=\"og:url\" " <>
           "content=\"www.example.com\"/></head></html>"

    assert {:ok, %{
      "og" => %{
        "url" => "www.example.com"
    }}} == Facebook.parse(html)
  end
end
