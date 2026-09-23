defmodule RulesProbe.MixProject do
  use Mix.Project

  def project do
    [app: :rules_probe, version: "0.1.0", elixir: "~> 1.19", deps: [{:popcorn, "0.4.0-next.0"}]]
  end

  def application do
    [extra_applications: [:logger], mod: {RulesProbe.Application, []}]
  end
end
