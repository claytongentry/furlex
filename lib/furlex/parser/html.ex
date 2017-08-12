defmodule Furlex.Parser.HTML do
  @behaviour Furlex.Parser

  alias Furlex.Parser.{Facebook, Twitter}

  @spec parse(String.t) :: nil | {:ok, Map.t}
  def parse(html) do
    case Floki.find(html, "meta[name]") do
      nil      ->
        {:ok, %{}}

      elements ->
        content =
          elements
          |> filter_other()
          |> Enum.reduce(%{}, &to_map/2)

        {:ok, content}
    end
  end

  # Filter out plain meta elements from Twitter, Facebook, etc.
  defp filter_other(elements) do
    Enum.reject elements, &(extract_attribute(&1, "name") in other_tags())
  end

  defp to_map(element, acc) do
    key    = extract_attribute(element, "name")
    value  = Map.get(acc, key)
    to_add = extract_attribute(element, "content") ||
             extract_attribute(element, "property")

    if is_nil(value) do
      Map.put(acc, key, to_add)
    else
      Map.put(acc, key, [to_add | value])
    end
  end

  defp extract_attribute(element, key) do
    case Floki.attribute(element, key) do
      nil       -> nil
      attribute -> Enum.at(attribute, 0)
    end
  end

  defp other_tags do
    Facebook.tags ++ Twitter.tags
  end
end
