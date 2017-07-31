# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :furlex, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:furlex, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :furlex, Furlex.Parser.Facebook,
  tags: ~w(
    fb:app_id fb:pages

    og:url og:title og:description og:image og:type og:locale og:video
    og:video:url og:video:secure_url og:video:type og:video:width
    og:video:height og:image:url og:image:secure_url og:image:type
    og:image:width og:image:height og:audio og:determiner og:locale:alternate
    og:site_name og:image:alt

    article:published_time article:modified_time
    article:expiration_time article:author article:section article:tag

    book:author book:isbn book:release_date book:tag

    profile:first_name profile:last_name profile:username profile:gender

    music:duration music:album music:album:disc music:album:track
    music:musician music:song music:song:disc music:song:track
    music:release_date music:creator

    video:actor video:actor:role video:director video:duration
    video:release_date video:tag video:writer video:series
  )

config :furlex, Furlex.Parser.Twitter,
  tags: ~w(
    twitter:card twitter:site twitter:domain twitter:url twitter:site:id
    twitter:creator twitter:creator:id twitter:description twitter:title
    twitter:image twitter:image:alt twitter:player twitter:player:width
    twitter:player:height twitter:player:stream twitter:app:name:iphone
    twitter:app:id:iphone twitter:app:url:iphone twitter:app:name:ipad
    twitter:app:id:ipad twitter:app:url:ipad twitter:app:name:googleplay
    twitter:app:url:googleplay twitter:app:id:googleplay
  )
