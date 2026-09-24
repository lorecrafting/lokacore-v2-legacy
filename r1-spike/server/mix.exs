# The durable runner's stdout carries only response lines: silence Mix's own
# messages (such as "Compiling N files") when the command is `mix r1.durable_runner`.
if List.first(System.argv()) == "r1.durable_runner", do: Mix.shell(Mix.Shell.Quiet)

defmodule LokaR1Server.MixProject do
  use Mix.Project

  def project do
    [
      app: :loka_r1_server,
      version: "0.1.0",
      elixir: "== 1.20.4",
      deps: [{:loka_r1, path: "../elixir"}, {:exqlite, "== 0.40.0"}]
    ]
  end

  def application do
    [extra_applications: [:crypto], mod: {LokaR1Server.Application, []}]
  end
end
