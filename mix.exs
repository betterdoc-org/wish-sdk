defmodule WishSdk.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/betterdoc-org/wish-sdk"

  def project do
    [
      app: :wish_sdk,
      name: "Wish SDK",
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),

      # Hex
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 0.20 or ~> 1.0"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.4"},
      {:ecto, ">= 3.0.0"},
      {:gettext, ">= 0.26.0"},
      {:earmark, "~> 1.4"},
      {:knigge, "~> 1.4"},

      # dev and test
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      formatters: ["html"],
      nest_modules_by_prefix: [WishSdk, WishSdk.Live]
    ]
  end

  defp description do
    """
    Elixir SDK for integrating BetterPrompt AI capabilities with LiveView components.
    """
  end

  def package do
    [
      files: [
        "lib",
        "mix.exs",
        ".formatter.exs",
        "README*",
        "package.json",
        "priv"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
