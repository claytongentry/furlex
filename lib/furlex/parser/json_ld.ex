defmodule Furlex.Parser.JsonLD do
  @behaviour Furlex.Parser

  def parse(html) do
    meta = "script[type=\"application/ld+json\"]"

    case Floki.find(html, meta) do
      nil      -> nil
      elements ->
        json_ld =
          elements
          |> Enum.map(&decode/1)
          |> List.flatten()

        {:ok, json_ld}
    end
  end

  defp decode(element) do
    element
    |> Floki.text(js: true)
    |> Poison.decode!()
  end
end
