defmodule Furlex.ParserTest do
  use ExUnit.Case

  alias Furlex.Parser

  doctest Parser

  test "extracts tags from html" do
    html = """
      <html><head><meta name=\"foobar\" content=\"foobaz\" /></head></html>
     """

     tags = Parser.extract ["foobar"], html, &("meta[name=\"#{&1}\"]")

     assert tags["foobar"] == "foobaz"
  end

  test "extracts canonical url from html" do
    html = "<html><head><link rel=\"canonical\" " <>
           "href=\"www.example.com\"/></head></html>"

    assert is_nil Parser.extract_canonical("foobar")
    assert Parser.extract_canonical(html) == "www.example.com"
  end
end
