defmodule Furlex.Parser.RDFTest do
  use ExUnit.Case

  alias Furlex.Parser.RDF

  doctest RDF

  test "parses RDF" do
    rdf =
      """
      <?xml version="1.0"?>

      <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:si="https://www.w3schools.com/rdf/">
      <rdf:Description rdf:about="https://www.w3schools.com">
        <si:title>W3Schools.com</si:title>
        <si:author>Jan Egil Refsnes</si:author>
      </rdf:Description>
      </rdf:RDF>
      """

    assert {:ok, [
      {"https://www.w3schools.com", "https://www.w3schools.com/rdf/title", "W3Schools.com"},
      {"https://www.w3schools.com", "https://www.w3schools.com/rdf/author", "Jan Egil Refsnes"}
    ]} == RDF.parse(rdf)
  end
end
