defmodule Furlex.Parser.TwitterTest do
  use ExUnit.Case

  alias Furlex.Parser.Twitter

  doctest Twitter

  test "parses Twitter Cards" do
    html =
      "<html><head><meta name=\"twitter:image\" " <>
        "content=\"www.example.com\"/></head></html>"

    assert {:ok,
            %{
              "twitter" => %{
                "image" => "www.example.com"
              }
            }} == Twitter.parse(html)
  end
end
