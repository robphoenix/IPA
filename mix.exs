defmodule Ipa.Mixfile do
  use Mix.Project

  def project do
    [app: :ipa,
     version: "0.0.3",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/bordeltabernacle/IPA",
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end

  defp description do
    """
    A pale, hoppy library for working with IP Addresses.
    Validate and transform IPv4 addresses and subnet masks.
    """
  end

  defp package do
    [name: :ipa,
     files: ["lib", "mix.exs", "README.md", "LICENSE", "test"],
     maintainers: ["Rob Phoenix"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/bordeltabernacle/IPA"}]
  end
end
