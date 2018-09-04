defmodule KSQL.MixProject do
  use Mix.Project

  def project do
    [
      app: :ksql,
      description: "Elixir KSQL client library.",
      version: "0.0.1-rc0",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # dialyzer: [ignore_warnings: "dialyzer.ignore-warnings", plt_add_deps: true],

      # Docs
      name: "ksql",
      source_url: "https://github.com/IanLuites/ksql",
      homepage_url: "https://github.com/IanLuites/ksql",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :ksql,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/ksql",
        "lib/ksql.ex",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/ksql"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpx, "~> 0.0.12"}
    ]
  end
end
