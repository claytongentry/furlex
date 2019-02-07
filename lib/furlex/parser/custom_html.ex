defmodule Furlex.Parser.CustomHTML do
  @behaviour Furlex.Parser

  @spec parse(String.t()) :: nil | {:ok, Map.t()}
  def parse(html) do
    {:ok, %{"title" => get_title(html), "description" => get_description(html)}}
  end

  defp get_title(html) do
    case Floki.find(html, "title") do
      [{_, _, [title]}] -> title
      _ -> nil
    end
  end

  defp get_description(html) do
    case Floki.find(html, "meta[name='description']") do
      [{_, list, _}] -> Enum.find_value(list, fn
        {"content", value} -> value
        _ -> nil
      end)
      _ -> nil
    end
  end
end
