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

  defp do_extract_content(elements) do
    Enum.map elements, fn element ->
      element
      |> Floki.attribute("content")
      |> Enum.at(0)
    end
  end
end
