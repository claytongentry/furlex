defmodule Furlex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :furlex,
      version: "0.3.4",
      elixir: "~> 1.6",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
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
      extra_applications: [:httpoison, :logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:bypass, "~> 0.8", only: :test},
      {:floki, "~> 0.20.3"},
      {:httpoison, "~> 1.2"},
      {:poison, "~> 3.0"}
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
        "Docs"   => "http://hexdocs.pm/furlex",
      }
    ]
  end
end
