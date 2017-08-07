defmodule Furlex.Parser do

  @callback parse(String.t) :: {:ok, Map.t} | {:error, Atom.t}

  @doc """
  Extracts the given tags from the given raw html according to
  the given match function

  ## Example

    html = ```
      <html><head><meta name="foobar" content="foobaz" /></head></html>
    ```

   Parser.extract ["foobar"], html, &("meta[name=&1]")
   => %{"foobar" => "foobaz"}
  """
  def extract(tags, html, match) when is_list(tags) do
    tags
    |> Stream.map(&extract(&1, html, match))
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> group_keys()
  end
  def extract(tag, html, match) do
    case Floki.find(html, match.(tag)) do
      nil      -> nil
      elements ->
        content = do_extract_content(elements)
        content =
          cond do
            length(content) == 0 -> nil
            length(content) == 1 -> Enum.at(content, 0)
            true                 -> content
          end

        {tag, content}
    end
  end

  @doc "Extracts a canonical url from the given raw HTML"
  def extract_canonical(html) do
    case Floki.find(html, "link[rel=\"canonical\"]") do
      []       -> nil
      elements ->
        elements
        |> Floki.attribute("href")
        |> Enum.at(0)
    end
  end

  @doc """
  Groups colon-separated keys into dynamic map structures

  ## Example

  iex> Furlex.Parser.group_keys %{"twitter:app:id" => 123, "twitter:app:name" => "YouTube"}
  %{
    "twitter" => %{
      "app" => %{
        "id" => 123,
        "name" => "YouTube"
      }
    }
  }
  """
  def group_keys(map) do
    Enum.reduce map, %{}, fn
      {_, v}, _acc when is_map(v) -> group_keys(v)
      {k, v}, acc                 -> do_group_keys(k, v, acc)
    end
  end

  defp do_group_keys(key, value, acc) do
    [h | t] = key |> String.split(":") |> Enum.reverse()
    base    = Map.new [{h, value}]
    result  = Enum.reduce t, base, fn key, sub_acc ->
      Map.new([{key, sub_acc}])
    end

    deep_merge(acc, result)
  end

  defp deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end
  defp deep_resolve(_key, _left, right) do
    right
  end

  defp do_extract_content(elements) do
    Enum.map elements, fn element ->
      element
      |> Floki.attribute("content")
      |> Enum.at(0)
    end
  end
end
