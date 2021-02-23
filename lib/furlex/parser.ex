defmodule Furlex.Parser do
  @doc """
  Parses the given HTML, returning a map structure of structured
  data keys mapping to their respective values, or an error.
  """
  @callback parse(html :: String.t()) :: {:ok, Map.t()} | {:error, Atom.t()}

  @doc """
  Extracts the given tags from the given raw html according to
  the given match function
  """
  @spec extract(List.t() | String.t(), String.t(), Function.t()) :: Map.t()
  def extract(tags, html, match) when is_list(tags) do
    tags
    |> Stream.map(&extract(&1, html, match))
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
    |> group_keys()
  end

  def extract(tag, html, match) do
    html
    |> Floki.parse_document()
    |> elem(1)
    |> Floki.find(match.(tag))
    |> case do
      nil ->
        nil

      elements ->
        content =
          case do_extract_content(elements) do
            [] -> nil
            [element] -> element
            content -> content
          end

        {tag, content}
    end
  end

  @doc "Extracts a canonical url from the given raw HTML"
  @spec extract_canonical(String.t()) :: nil | String.t()
  def extract_canonical(html) do
    html
    |> Floki.parse_document()
    |> elem(1)
    |> Floki.find("link[rel=\"canonical\"]")
    |> case do
      [] ->
        nil

      elements ->
        elements
        |> Floki.attribute("href")
        |> Enum.at(0)
    end
  end

  @doc """
  Groups colon-separated keys into dynamic map structures

  ## Examples

    iex> Application.put_env(:furlex, :group_keys?, false)
    iex> Furlex.Parser.group_keys %{"twitter:app:id" => 123, "twitter:app:name" => "YouTube"}
    %{"twitter:app:id" => 123, "twitter:app:name" => "YouTube"}

    iex> Application.put_env(:furlex, :group_keys?, true)
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
  @spec group_keys(Map.t()) :: Map.t()
  def group_keys(map)

  def group_keys(map) do
    if Application.get_env(:furlex, :group_keys?) do
      Enum.reduce(map, %{}, fn
        {_, v}, _acc when is_map(v) -> group_keys(v)
        {k, v}, acc -> do_group_keys(k, v, acc)
      end)
    else
      map
    end
  end

  defp do_group_keys(key, value, acc) do
    [h | t] = key |> String.split(":") |> Enum.reverse()
    base = Map.new([{h, value}])

    result =
      Enum.reduce(t, base, fn key, sub_acc ->
        Map.new([{key, sub_acc}])
      end)

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
    Enum.map(elements, fn element ->
      element
      |> Floki.attribute("content")
      |> Enum.at(0)
    end)
  end
end
