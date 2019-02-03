## Parsers

### Vimeo
vimeo = File.read! "./test/fixtures/vimeo.html"

Benchee.run(%{
  "facebook" => fn -> Furlex.Parser.Facebook.parse(vimeo) end,
  "twitter" => fn -> Furlex.Parser.Twitter.parse(vimeo) end,
  "json_ld" => fn -> Furlex.Parser.JsonLD.parse(vimeo) end,
  "html" => fn -> Furlex.Parser.HTML.parse(vimeo) end
})
