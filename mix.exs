defmodule Pimp.Mixfile do
  use Mix.Project

  def project do
    [
      app:               :ex_cut,
      version:           "0.1.0",
      elixir:            "~> 1.5",
      start_permanent:   Mix.env == :prod,
      deps:              deps(),
      test_coverage:     [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls":        :test,
        "coveralls.detail": :test,
        "coveralls.post":   :test,
        "coveralls.html":   :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc     , "~> 0.18.1", only: :dev},
      {:dogma      , "~> 0.1.15", only: :dev},
      {:excoveralls, "~> 0.7.4" , only: :test}
    ]
  end
end
