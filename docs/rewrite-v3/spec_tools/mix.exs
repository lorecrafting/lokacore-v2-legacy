defmodule LokaSpec.MixProject do
  use Mix.Project

  @spec project() :: keyword()
  def project do
    [app: :loka_spec, version: "0.1.0", elixir: "== 1.20.4", deps: []]
  end

  @spec application() :: keyword()
  def application do
    [extra_applications: [:crypto]]
  end
end
