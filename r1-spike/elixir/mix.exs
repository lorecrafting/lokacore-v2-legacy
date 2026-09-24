# The runner's stdout carries only response lines: silence Mix's own messages
# (such as "Compiling N files") when the command is `mix r1.runner`.
if List.first(System.argv()) == "r1.runner", do: Mix.shell(Mix.Shell.Quiet)

defmodule LokaR1.MixProject do
  use Mix.Project

  def project do
    [app: :loka_r1, version: "0.1.0", elixir: "== 1.20.4", deps: []]
  end

  def application do
    [extra_applications: [:crypto]]
  end
end
