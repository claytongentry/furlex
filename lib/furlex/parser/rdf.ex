defmodule Furlex.Parser.RDF do

  @moduledoc """
  Parses an RDF structure into a list of triples.

  Each triple is represented by a tuple of the
  format {<subject>, <predicate>, <object>}
  """

  @spec parse(String.t) :: {:ok, List.t}
  def parse(rdf) do

  end
end
