defmodule LokaR1Harness.MixProject do
  use Mix.Project

  def project do
    [
      app: :loka_r1_harness,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: false,
      deps: []
    ]
  end

  def application, do: [extra_applications: []]
end
