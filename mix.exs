defmodule ExCut.Mixfile do
  use Mix.Project

  def project do
    [
      app:               :ex_cut,
      version:           "0.1.0",
      description:       description(),
      source_url:        "https://github.om/derailed/ex_cut",
      package:           package(),
      docs:              docs(),
      elixir:            "~> 1.5",
      start_permanent:   Mix.env == :prod,
      deps:              deps(),
      test_coverage:     [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls:        :test,
        "coveralls.html": :test
      ],
      dialyzer:          [plt_add_deps: :transitive]
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
      {:ex_doc        , "~> 0.18.1", only: :dev},
      {:dogma         , "~> 0.1.15", only: :dev},
      {:credo         , "~> 0.8"   , only: [:dev, :test], runtime: false},
      {:excoveralls   , "~> 0.7.4" , only: :test},
      {:mix_test_watch, "~> 0.3"   , only: :dev, runtime: false},
      {:dialyxir      , "~> 0.5"   , only: [:dev], runtime: false}
    ]
  end

  defp description do
    """
    ExCut provides an annotation mechanism to inject cross-cutting
    concerns to a function.
    """
  end

  defp package do
   [
      licenses:     ["Apache 2.0"],
      organization: "ImhotepSoftware",
      maintainers:  ["Fernand Galiana"],
      files:        ["lib", "mix.exs", "README.md"],
      links:        %{"GitHub" => "https://github.com/derailed/ex_cut"}
    ]
  end

  defp docs do
    [
      main:   "ExCut",
      logo:   "assets/ex_cut.png",
      extras: ["README.md"]
    ]
  end
end
