defmodule Furlex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :furlex,
      version: "0.5.0",
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Furlex",
      source_url: "https://github.com/fanhero/furlex",
      docs: [
        main: "Furlex",
        extras: ~w(README.md CHANGELOG.md)
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      mod: {Furlex, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17", optional: true}, # optional, but recommended adapter for tesla
      {:floki, "~> 0.32"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:bypass, "~> 2.1", only: :test},
      # {:fetch_favicon, "~> 0.1.3"},
      {:fetch_favicon, git: "https://github.com/bonfire-networks/fetch_favicon", branch: "master"}
    ]
  end

  defp description do
    """
    Furlex is a structured data extraction tool written in Elixir.

    It currently supports unfurling oEmbed, Twitter Card, Facebook Open Graph, JSON-LD
    and plain ole' HTML `<meta />` data out of any url you supply.
    """
  end

  defp package do
    [
      name: :furlex,
      files: ~w(doc lib mix.exs README.md LICENSE.md CHANGELOG.md),
      maintainers: ["Clayton Gentry"],
      licenses: ["Apache 2.0"],
      links: %{
        "Github" => "http://github.com/claytongentry/furlex",
        "Docs" => "http://hexdocs.pm/furlex"
      }
    ]
  end
end
