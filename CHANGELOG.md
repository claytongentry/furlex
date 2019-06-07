# Changelog

## v.0.4.2
* Don't require oembed host configuration

## v.0.4.1
* Various dependency updates

## v.0.4.0
* Make json library configurable, default to Jason ([abitdodgy](https://github.com/abitdodgy))
* Bump HTTPoison to 1.5 ([abitdodgy](https://github.com/abitdodgy))

## v.0.3.3
* Supports fetch options passed through unfurl (thanks [aliou](https://github.com/aliou)!)

## v.0.3.2
* Remove usage of Mix.env() for segmenting app logic. Instead, leverage test bypasses where needed (h/t [Luciam91](https://github.com/Luciam91))
* Strip out needless cruft from test fixtures.

## v.0.3.1
* Fix handling of duplicate HTML meta tags

## v.0.3.0
* Individual fetch and parse operations now run asynchronously

## v.0.2.2
* Furlex now supports passing HTTP options to Furlex.unfurl/2.
* `:depth` config has been transformed to a `:group_keys?` boolean.

## v.0.2.1
* Add status code to %Furlex{} structure (thanks [abitdodgy](https://github.com/abitdodgy))
* Fix compatibility with Phoenix 1.3 (thanks, again, [abitdodgy](https://github.com/abitdodgy)!)

## v.0.2.0
* Support configuration for grouping colon-delimited keys into map structures
* Don't require explicitly configuring OpenGraph and TwitterCard tags in your app config.
* Enable adding custom tags under OpenGraph and TwitterCard parsers.

## v.0.1.3
* Add typespecs, better examples to documentation

## v.0.1.2
* Parse colon-separated OpenGraph and Twitter Card keywords into map structures
  - E.g. %{"twitter:app:id" => 123} becomes %{"twitter" => %{"app" => %{"id" => 123}}}

## v.0.1.1
* Fix test-breaking bug when included as hex dependency
* Add tags

## v.0.1.0
* Support unfurling oEmbed, Facebook Open Graph, Twitter Card, JSON-LD and other HTML meta tags.
* Extract canonical urls
