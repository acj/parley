defmodule Parley.Mixfile do
  use Mix.Project

  def project do
    [app: :parley,
     version: "0.1.0",
     elixir: "~> 1.4",
     description: description(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     consolidate_protocols: Mix.env != :test]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Parley, []}]
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
    []
  end

  defp description do
    """
    A web-based remote shell for Elixir apps. Parley provides an IEx-like REPL
    for running applications. It uses websockets for transport and can be used
    from any browser.
    """
  end

  defp package do
    [
      name: :parley,
      files: ["lib", "priv", "web", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Adam Jensen"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/acj/parley"}
    ]
  end
end
