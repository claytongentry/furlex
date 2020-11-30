defmodule Furlex.Parser.JsonLD do
  @behaviour Furlex.Parser

  @json_library Application.get_env(:furlex, :json_library, Jason)

  @spec parse(String.t()) :: nil | {:ok, List.t()}
  def parse(html) do
    meta = "script[type=\"application/ld+json\"]"

    with {:ok, document} <- Floki.parse_document(html) do
      case Floki.find(document, meta) do
        nil ->
          {:ok, []}

        elements ->
          json_ld =
            elements
            |> Enum.map(&decode/1)
            |> List.flatten()

          {:ok, json_ld}
      end
    end
  end

  defp decode(element) do
    element
    |> Floki.text(js: true)
    |> @json_library.decode!()
  end
end
