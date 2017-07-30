defmodule Furlex do
  @moduledoc """
  Furlex unfurls urls.
  """

  use Application

  alias Furlex.{Fetcher, Parser}
  alias Furlex.Parser.{Facebook, HTML, JsonLD, Twitter}

  defstruct [:canonical_url, :oembed, :facebook, :twitter, :json_ld, :other]

  def start(_type, _args) do
    import Supervisor.Spec

    opts     = [strategy: :one_for_one, name: Furlex.Supervisor]
    children = [
      worker(Furlex.Oembed, [[name: Furlex.Oembed]]),
    ]

    Supervisor.start_link(children, opts)
  end

  @doc """
  Unfurls a url

  unfurl/1 fetches oembed data if applicable to the given url's host,
  in addition to Twitter Card, Open Graph, JSON-LD and other HTML meta tags.

  ## Example

    Furlex.unfurl "https://www.youtube.com/watch?v=Gh6H7Md_L2k"
    => {:ok, %Furlex{
        canonical_url: "https://www.youtube.com/watch?v=Gh6H7Md_L2k",
        facebook: %{
          "fb:app_id" => "87741124305",
          "og:image" => "https://i.ytimg.com/vi/Gh6H7Md_L2k/maxresdefault.jpg",
          "og:site_name" => "YouTube"
          ...
        }
        json_ld: [
          %{
            "@context" => "http://schema.org",
            "@type" => "BreadcrumbList",
            ...
          }
        ],
        oembed: %{
          "author_name" => "This Old House",
          "author_url" => "https://www.youtube.com/user/thisoldhouse",
          ...
        },
        other: %{
          "description" => "Watch the full episode: https://www.thisoldhouse.com/watch/ask-toh-future-house-offerman Ask This Old House host Kevin O’Connor visits Nick Offerman in Los A...",
          "keywords" => "this old house, how-to, home improvement, Episode, TV Show, DIY, Ask This Old House, Nick Offerman, Kevin O'Connor, woodworking, wood shop",
          ...
        },
        twitter: %{
          "twitter:app:id:googleplay" => "com.google.android.youtube",
          "twitter:app:id:ipad" => "544007664",
          "twitter:app:id:iphone" => "544007664",
          "twitter:app:name:googleplay" => "YouTube"
          ...
        }
      }}
  """
  def unfurl(url) do
    with {:ok, body}     <- Fetcher.fetch(url),
         {:ok, oembed}   <- Fetcher.fetch_oembed(url),
         {:ok, facebook} <- Facebook.parse(body),
         {:ok, twitter}  <- Twitter.parse(body),
         {:ok, json_ld}  <- JsonLD.parse(body),
         {:ok, other}    <- HTML.parse(body)
    do
      {:ok, %__MODULE__{
        canonical_url: Parser.extract_canonical(body),
        oembed: oembed,
        facebook: facebook,
        twitter: twitter,
        json_ld: json_ld,
        other: other
      }}
    end
  end
end
