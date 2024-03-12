defmodule Furlex.RelMeTest do
  use ExUnit.Case
  import Tesla.Mock
  import Untangle

  setup_all do
    Tesla.Mock.mock_global(fn

      %{method: :get, url: url} ->
        get(url, nil, nil, nil)
      _ ->
        %Tesla.Env{status: 304, body: "{error: 'No implemented mock response'}"}
    end)
    |> IO.inspect(label: "setup done")

    :ok
  end

  def get("http://example.com/rel_me/anchor", _, _, _) do
    {:ok, %Tesla.Env{status: 200, body: ("../../fixtures/rel_me_anchor.html") |> Path.expand(__DIR__)
      |> File.read!()}}
  end

  def get("http://example.com/rel_me/anchor_nofollow", _, _, _) do
    {:ok, %Tesla.Env{status: 200, body: ("../../fixtures/rel_me_anchor_nofollow.html") |> Path.expand(__DIR__)
      |> File.read!()}}
  end

  def get("http://example.com/rel_me/link", _, _, _) do
    {:ok, %Tesla.Env{status: 200, body: ("../../fixtures/rel_me_link.html") |> Path.expand(__DIR__)
      |> File.read!()}}
  end

  def get("http://example.com/rel_me/third_party", _, _, _) do
    {:ok, %Tesla.Env{status: 200, body: ("../../fixtures/rel_me_third_party.html") |> Path.expand(__DIR__)
      |> File.read!()}}
  end

  def get("http://example.com/rel_me/null", _, _, _) do
    {:ok, %Tesla.Env{status: 200, body: ("../../fixtures/rel_me_null.html") |> Path.expand(__DIR__)
      |> File.read!()}}
  end

  def get("https://oembed.com/providers.json", _, _, _) do
    {:ok, %Tesla.Env{status: 200, body: ("../../fixtures/providers.json") |> Path.expand(__DIR__)
      |> File.read!()}}
  end
  def get(_, _, _, _) do
        %Tesla.Env{status: 304, body: "{error: 'No implemented mock response'}"}
  end

describe "rel_me" do
    
    
  test "parse works for valid rel=me links" do
    hrefs = ["https://social.example.org/users/test"]

    assert {:ok, %{rel_me: nil}} = Furlex.unfurl("http://example.com/rel_me/null") 

    assert {:ok, %{rel_me: %{urls: ["https://social.example.org/users/test2nd", "https://social.example.org/users/test3rd"]}}} = Furlex.unfurl("http://example.com/rel_me/third_party") 

    assert {:ok, %{rel_me: nil}} =
             Furlex.unfurl("http://example.com/rel_me/error")

    assert {:ok, %{rel_me: %{urls: hrefs}}} = Furlex.unfurl("http://example.com/rel_me/link") 
    assert {:ok, %{rel_me: %{urls: hrefs}}} = Furlex.unfurl("http://example.com/rel_me/anchor")
    assert {:ok, %{rel_me: %{urls: hrefs}}} = Furlex.unfurl("http://example.com/rel_me/anchor_nofollow") 
  end

  test "parse returns true for valid rel=me links when actor link provided" do
    hrefs = ["https://social.example.org/users/test"]

    assert {:ok, %{rel_me: nil}} = Furlex.unfurl("http://example.com/rel_me/null", rel_me_urls: hrefs)  

    assert {:ok, %{rel_me: %{urls: ["https://social.example.org/users/test2nd", "https://social.example.org/users/test3rd"]}}} = Furlex.unfurl("http://example.com/rel_me/third_party", rel_me_urls: hrefs) 

    assert {:ok, %{rel_me: nil}} =
             Furlex.unfurl("http://example.com/rel_me/error", rel_me_urls: hrefs)

    assert {:ok, %{rel_me: %{urls: hrefs, verified: true}}} = Furlex.unfurl("http://example.com/rel_me/link", rel_me_urls: hrefs) 
    assert {:ok, %{rel_me: %{urls: hrefs, verified: true}}} = Furlex.unfurl("http://example.com/rel_me/anchor", rel_me_urls: hrefs) 
    assert {:ok, %{rel_me: %{urls: hrefs, verified: true}}} = Furlex.unfurl("http://example.com/rel_me/anchor_nofollow", rel_me_urls: hrefs) 
  end

  end  
    
end
