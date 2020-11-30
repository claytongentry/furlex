defmodule Furlex.Parser.HTML do
  @behaviour Furlex.Parser

  alias Furlex.Parser.{Facebook, Twitter}

  @spec parse(String.t()) :: nil | {:ok, Map.t()}
  def parse(html) do
    with {:ok, document} <- Floki.parse_document(html) do
      case Floki.find(document, "meta[name]") do
        nil ->
          {:ok, %{}}

        elements ->
          content =
            elements
            |> filter_other()
            |> Enum.reduce(%{}, &to_map/2)

          {:ok, content}
      end
    end
  end

  # Filter out plain meta elements from Twitter, Facebook, etc.
  defp filter_other(elements) do
    Enum.reject(elements, fn element ->
      extract_attribute(element, "name") in (Facebook.tags() ++ Twitter.tags())
    end)
  end

  defp to_map(element, acc) do
    key = extract_attribute(element, "name")
    existing = Map.get(acc, key)

    to_add =
      extract_attribute(element, "content") ||
        extract_attribute(element, "property")

    if is_nil(existing) do
      Map.put(acc, key, to_add)
    else
      value =
        to_add
        |> prepend(existing)
        |> Enum.uniq()
        |> case do
          [element] -> element
          list -> list
        end

      Map.put(acc, key, value)
    end
  end

  defp extract_attribute(element, key) do
    case Floki.attribute(element, key) do
      [attribute] -> attribute
      _ -> nil
    end
  end

  defp prepend(value, list) when is_list(list), do: [value | list]
  defp prepend(value, element), do: [value | [element]]
end
