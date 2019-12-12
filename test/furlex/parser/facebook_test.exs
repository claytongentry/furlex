defmodule Furlex.Parser.FacebookTest do
  use ExUnit.Case, async: true

  alias Furlex.Parser.Facebook

  doctest Facebook

  setup do
    Application.put_env(:furlex, :group_keys?, true)
  end

  test "parses Facebook Open Graph" do
    html =
      "<html><head><meta property=\"og:url\" " <>
        "content=\"www.example.com\"/></head></html>"

    assert {:ok,
            %{
              "og" => %{
                "url" => "www.example.com"
              }
            }} == Facebook.parse(html)
  end
end
