# Furlex

Furlex is a [structured data](https://moz.com/learn/seo/schema-structured-data) extraction tool written in Elixir.

It currently supports unfurling oEmbed, Twitter Card, Facebook Open Graph, JSON-LD
and plain ole' HTML `<meta />` data out of any url you supply.

## Installation

Add `:furlex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:furlex, "~> 0.1.0"}]
end
```

Then run `$ mix deps.get`. Also add `:furlex` to your applications list:

```elixir
def application do
  [applications: [:furlex]]
end
```

## Usage
To unfurl a url, simply pass it to `Furlex.unfurl/1`

```elixir
iex(1)> Furlex.unfurl "https://www.youtube.com/watch?v=Gh6H7Md_L2k"
{:ok,
 %Furlex{canonical_url: "https://www.youtube.com/watch?v=Gh6H7Md_L2k",
  facebook: %{"fb:app_id" => "87741124305",
    "og:description" => "Watch the full episode: https://www.thisoldhouse.com/watch/ask-toh-future-house-offerman Ask This Old House host Kevin O’Connor visits Nick Offerman in Los A...",
    "og:image" => "https://i.ytimg.com/vi/Gh6H7Md_L2k/maxresdefault.jpg",
    "og:site_name" => "YouTube",
    "og:title" => "Touring Nick Offerman’s Wood Shop", "og:type" => "video",
    "og:url" => "https://www.youtube.com/watch?v=Gh6H7Md_L2k",
    "og:video:height" => ["720", "720"],
    "og:video:secure_url" => ["https://www.youtube.com/embed/Gh6H7Md_L2k",
     "https://www.youtube.com/v/Gh6H7Md_L2k?version=3&autohide=1"],
    "og:video:type" => ["text/html", "application/x-shockwave-flash"],
    "og:video:url" => ["https://www.youtube.com/embed/Gh6H7Md_L2k",
     "http://www.youtube.com/v/Gh6H7Md_L2k?version=3&autohide=1"],
    "og:video:width" => ["1280", "1280"]},
  json_ld: [%{"@context" => "http://schema.org", "@type" => "BreadcrumbList",
     "itemListElement" => [%{"@type" => "ListItem",
        "item" => %{"@id" => "http://www.youtube.com/user/thisoldhouse",
          "name" => "This Old House"}, "position" => 1}]}],
  oembed: %{"author_name" => "This Old House",
    "author_url" => "https://www.youtube.com/user/thisoldhouse",
    "height" => 270,
    "html" => "<iframe width=\"480\" height=\"270\" src=\"https://www.youtube.com/embed/Gh6H7Md_L2k?feature=oembed\" frameborder=\"0\" allowfullscreen></iframe>",
    "provider_name" => "YouTube", "provider_url" => "https://www.youtube.com/",
    "thumbnail_height" => 360,
    "thumbnail_url" => "https://i.ytimg.com/vi/Gh6H7Md_L2k/hqdefault.jpg",
    "thumbnail_width" => 480, "title" => "Touring Nick Offerman’s Wood Shop",
    "type" => "video", "version" => "1.0", "width" => 480},
  other: %{"description" => "Watch the full episode: https://www.thisoldhouse.com/watch/ask-toh-future-house-offerman Ask This Old House host Kevin O’Connor visits Nick Offerman in Los A...",
    "keywords" => "this old house, how-to, home improvement, Episode, TV Show, DIY, Ask This Old House, Nick Offerman, Kevin O'Connor, woodworking, wood shop",
    "theme-color" => "#e62117",
    "title" => "Touring Nick Offerman’s Wood Shop"},
  twitter: %{"twitter:app:id:googleplay" => "com.google.android.youtube",
    "twitter:app:id:ipad" => "544007664",
    "twitter:app:id:iphone" => "544007664",
    "twitter:app:name:googleplay" => "YouTube",
    "twitter:app:name:ipad" => "YouTube",
    "twitter:app:name:iphone" => "YouTube",
    "twitter:app:url:googleplay" => "https://www.youtube.com/watch?v=Gh6H7Md_L2k",
    "twitter:app:url:ipad" => "vnd.youtube://www.youtube.com/watch?v=Gh6H7Md_L2k&feature=applinks",
    "twitter:app:url:iphone" => "vnd.youtube://www.youtube.com/watch?v=Gh6H7Md_L2k&feature=applinks",
    "twitter:card" => "player",
    "twitter:description" => "Watch the full episode: https://www.thisoldhouse.com/watch/ask-toh-future-house-offerman Ask This Old House host Kevin O’Connor visits Nick Offerman in Los A...",
    "twitter:image" => "https://i.ytimg.com/vi/Gh6H7Md_L2k/maxresdefault.jpg",
    "twitter:player" => "https://www.youtube.com/embed/Gh6H7Md_L2k",
    "twitter:player:height" => "720", "twitter:player:width" => "1280",
    "twitter:site" => "@youtube",
    "twitter:title" => "Touring Nick Offerman’s Wood Shop",
    "twitter:url" => "https://www.youtube.com/watch?v=Gh6H7Md_L2k"}}}
```

## License
Copyright 2017 Clayton Gentry

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
```
http://www.apache.org/licenses/LICENSE-2.0`
```
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.