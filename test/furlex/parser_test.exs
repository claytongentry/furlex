defmodule Furlex.ParserTest do
  use ExUnit.Case

  alias Furlex.Parser

  doctest Parser

  setup do
    Application.put_env(:furlex, :group_keys?, true)
  end

  test "extracts tags from html" do
    html = """
      <html><head><meta name=\"foobar\" content=\"foobaz\" /></head></html>
    """

    tags = Parser.extract(["foobar"], html, &"meta[name=\"#{&1}\"]")

    assert tags["foobar"] == "foobaz"
  end

  test "extracts canonical url from html" do
    html =
      "<html><head><link rel=\"canonical\" " <>
        "href=\"www.example.com\"/></head></html>"

    assert is_nil(Parser.extract_canonical("foobar"))
    assert Parser.extract_canonical(html) == "www.example.com"
  end

  test "groups keys" do
    map = %{
      "twitter:app:id:googleplay" => "com.google.android.youtube",
      "twitter:app:id:ipad" => "544007664",
      "twitter:app:name:googleplay" => "YouTube",
      "twitter:app:name:iphone" => "YouTube",
      "twitter:card" => "player"
    }

    result = Parser.maybe_group_keys(map)

    assert result == %{
             "twitter" => %{
               "app" => %{
                 "id" => %{
                   "googleplay" => "com.google.android.youtube",
                   "ipad" => "544007664"
                 },
                 "name" => %{
                   "googleplay" => "YouTube",
                   "iphone" => "YouTube"
                 }
               },
               "card" => "player"
             }
           }
  end
end
