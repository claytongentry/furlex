defmodule Furlex.Parser.JsonLDTest do
  use ExUnit.Case

  alias Furlex.Parser.JsonLD

  doctest JsonLD

  test "parses JSON-LD" do
    html =
      """
      <html><head><script id="jsonld-website" type="application/ld+json">
        {
          "@type":"WebSite","name":"Example","@context":"http://schema.org",
          "url":"https://www.example.com"
        }
     </script></head></html>
     """

     assert {:ok, [json_ld]} = JsonLD.parse(html)

     assert Map.get(json_ld, "@context") == "http://schema.org"
     assert Map.get(json_ld, "name")     == "Example"
     assert Map.get(json_ld, "@type")    == "WebSite"
     assert Map.get(json_ld, "url")      == "https://www.example.com"
  end
end
