
defmodule Furlex.Parser.RelMe do
    import Untangle

  def parse(html, opts \\ []) 
  def parse(html_tree, opts) when is_list(html_tree) do
    with rel_me_hrefs when is_list(rel_me_hrefs) and rel_me_hrefs != [] <-
           Floki.attribute(html_tree, "link[rel~=me]", "href") ++
             Floki.attribute(html_tree, "a[rel~=me]", "href") do

    case opts[:rel_me_urls] do
        rel_me_urls when is_list(rel_me_urls) ->

      {:ok, %{urls: rel_me_hrefs, verified: Enum.any?(rel_me_hrefs, fn x -> x in rel_me_urls end)}}

      _ ->
        # no url(s) provided to verify against
        {:ok, %{urls: rel_me_hrefs}}
    end

    else e ->
        warn(e,  "Parsing error with rel=me")
        {:ok, nil}
    end
    
  end
  def parse(html, opts) when is_list(html) do
    with {:ok, html_tree} <- Floki.parse_document(html) do
        parse(html_tree, opts)
    else e ->
        warn(e,  "Parsing error with rel=me")
        {:ok, nil}
    end
    
  end
  def parse(html, opts) do
    warn(html,  "Invalid HTML")
    {:ok, nil}
  end

end
