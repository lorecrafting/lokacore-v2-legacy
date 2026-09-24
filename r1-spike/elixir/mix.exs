defmodule LokaR1.MixProject do
  use Mix.Project

  def project do
    [app: :loka_r1, version: "0.1.0", elixir: "== 1.20.4", deps: []]
  end

  def application do
    [extra_applications: [:crypto]]
  end
end
