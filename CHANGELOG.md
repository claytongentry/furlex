# Changelog

## v.0.1.2
* Parse colon-separated OpenGraph and Twitter Card keywords into map structures
  - E.g. %{"twitter:app:id" => 123} becomes %{"twitter" => %{"app" => %{"id" => 123}}}

## v.0.1.1
* Fix test-breaking bug when included as hex dependency
* Add tags

## v.0.1.0
* Support unfurling oEmbed, Facebook Open Graph, Twitter Card, JSON-LD and other HTML meta tags.
* Extract canonical urls
