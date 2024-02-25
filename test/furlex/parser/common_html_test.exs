defmodule Furlex.Parser.CommonHTMLTest do
  use ExUnit.Case

  alias Furlex.Parser.HTML

  test "parses CustomHTML meta data" do
    html =
      [ __DIR__ | ~w(.. .. fixtures test.html) ]
      |> Path.join()
      |> File.read!()

    assert {:ok, meta} = HTML.parse(html)
    assert meta == %{
      "title" => "Test HTML",
      "description" => "This is test content."
    }
  end

  test "dedupes meta data" do
    html =
      [ __DIR__ | ~w(.. .. fixtures duplicate_meta.html) ]
      |> Path.join()
      |> File.read!()

    assert {:ok, meta} = HTML.parse(html)
    # IO.inspect(meta)

    assert meta["generator"] == "Loja Integrada"
    assert meta["google-site-verification"] == [
      "GbnYBmQLHGrgQRVEi4b2fzcrAA81TMh86T3Z1kDDW-c",
      "og5Ef6ntOLY0CrU0H8mURx_WwrlZc9Hz2HDXQGWOdAg",
      "66Kpz8sWyMtS35U7Eodir6sXoV5gJe7a9kNN9xQQnYE"
    ]
    assert meta["robots"] == "index, follow"

    # Ensure resultant meta is encodable
    assert {:ok, _json} = Jason.encode(meta)
  end
end
