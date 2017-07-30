defmodule Furlex.Parser.HTML do
  @behaviour Furlex.Parser

  alias Furlex.Parser.{Facebook, Twitter}

  def parse(html) do
    case Floki.find(html, "meta[name]") do
      nil      -> nil
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
    tags = tags()

    Enum.reject elements, &(extract_attribute(&1, "name") in tags)
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

  defp tags() do
    facebook = Application.get_env(:furlex, Facebook)[:tags]
    twitter  = Application.get_env(:furlex, Twitter)[:tags]

    facebook ++ twitter
  end
end
