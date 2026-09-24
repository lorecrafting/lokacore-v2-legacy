defmodule LokaR1Harness.Diff do
  @moduledoc """
  Differential runner: feeds generated request lines to two long-lived runner
  processes and compares their response lines byte for byte.

  Runners are assumed stateless across lines (each request is self-contained), so
  one pair of processes serves the whole run, including minimization.
  """

  alias LokaR1Harness.{Canonical, Generator}

  @max_line 65_536

  @doc """
  Options: `:runners` — `[{name, command, dir}, {name, command, dir}]`;
  `:seeds` — `[{origin, seed}]`; `:timeout` — ms per response.

  Returns `{:pass | :mismatch | :runner_failure, stats, failure | nil}`.
  """
  def run(opts) do
    [a, b] = Enum.map(opts[:runners], &open/1)
    timeout = opts[:timeout] || 60_000
    stats = %{requests: 0, fns: %{}, lengths: %{}}

    try do
      Enum.reduce_while(opts[:seeds], {:pass, stats, nil}, fn {origin, seed}, {_, stats, _} ->
        case run_sequence(a, b, timeout, seed, stats) do
          {:ok, stats} ->
            {:cont, {:pass, stats, nil}}

          {:mismatch, stats, req, ra, rb} ->
            failure = mismatch(a, b, timeout, origin, seed, req, ra, rb, opts[:on_mismatch])
            {:halt, {:mismatch, stats, failure}}

          {:runner_failure, stats, reason} ->
            {:halt,
             {:runner_failure, stats, %{"origin" => origin, "seed" => seed, "reason" => reason}}}
        end
      end)
    after
      close(a)
      close(b)
    end
  end

  defp run_sequence(a, b, timeout, seed, stats) do
    Enum.reduce_while(Generator.sequence(seed), {:ok, stats}, fn req, {:ok, stats} ->
      stats = count(stats, req)

      case exchange(a, b, timeout, Generator.line(req)) do
        {:same, _} -> {:cont, {:ok, stats}}
        {:differ, ra, rb} -> {:halt, {:mismatch, stats, req, ra, rb}}
        {:error, reason} -> {:halt, {:runner_failure, stats, reason}}
      end
    end)
  end

  defp count(stats, req) do
    name = Generator.fn_name(req)

    stats = %{
      stats
      | requests: stats.requests + 1,
        fns: Map.update(stats.fns, name, 1, &(&1 + 1))
    }

    case req do
      {:json, %{"fn" => "world.run", "commands" => cmds}} ->
        %{stats | lengths: Map.update(stats.lengths, length(cmds), 1, &(&1 + 1))}

      _ ->
        stats
    end
  end

  defp mismatch(a, b, timeout, origin, seed, req, ra, rb, notify) do
    failure = %{
      "origin" => origin,
      "seed" => seed,
      "request" => Generator.line(req),
      "responses" => %{a.name => printable(ra), b.name => printable(rb)}
    }

    # Retain the unminimized failure before minimizing, in case minimization dies.
    if notify, do: notify.(failure)
    minimal = minimize(req, &differs?(a, b, timeout, &1))
    line = Generator.line(minimal)

    responses =
      case exchange(a, b, timeout, line) do
        {:differ, ma, mb} -> %{a.name => printable(ma), b.name => printable(mb)}
        other -> %{"error" => inspect(other)}
      end

    Map.put(failure, "minimized", %{"request" => line, "responses" => responses})
  end

  # Response bytes that are not UTF-8 cannot sit in a JSON string.
  defp printable(bytes),
    do: if(String.valid?(bytes), do: bytes, else: "base64:" <> Base.encode64(bytes))

  defp differs?(a, b, timeout, req),
    do: match?({:differ, _, _}, exchange(a, b, timeout, Generator.line(req)))

  @doc """
  Delta-debugging over `world.run` commands: repeatedly deletes chunks (halving the
  chunk size down to one) while `fails?` still holds. Other requests are returned as is.
  """
  def minimize({:json, %{"fn" => "world.run", "commands" => cmds} = req}, fails?) do
    with_cmds = fn cs -> {:json, %{req | "commands" => cs}} end
    cmds = ddmin(cmds, max(div(length(cmds), 2), 1), &fails?.(with_cmds.(&1)))
    with_cmds.(cmds)
  end

  def minimize(req, _fails?), do: req

  defp ddmin(cmds, chunk, fails?) do
    candidate =
      0..(length(cmds) - 1)//chunk
      |> Stream.map(fn start -> Enum.take(cmds, start) ++ Enum.drop(cmds, start + chunk) end)
      |> Enum.find(&(&1 != [] and fails?.(&1)))

    cond do
      candidate -> ddmin(candidate, min(chunk, max(div(length(candidate), 2), 1)), fails?)
      chunk > 1 -> ddmin(cmds, div(chunk, 2), fails?)
      true -> cmds
    end
  end

  # ------------------------------------------------------------------ ports

  defp open({name, command, dir}) do
    [exe | args] = String.split(command)
    path = System.find_executable(exe) || raise "runner #{name}: #{exe} not found on PATH"

    port =
      Port.open({:spawn_executable, path}, [
        :binary,
        :exit_status,
        :use_stdio,
        {:line, @max_line},
        {:args, args},
        {:cd, Path.expand(dir)}
      ])

    %{name: name, port: port}
  end

  defp close(%{port: port}) do
    if Port.info(port), do: Port.close(port)
  catch
    _, _ -> :ok
  end

  defp exchange(a, b, timeout, line) do
    send(a.port, {self(), {:command, [line, ?\n]}})
    send(b.port, {self(), {:command, [line, ?\n]}})

    with {:ok, ra} <- read(a, timeout, []),
         {:ok, rb} <- read(b, timeout, []) do
      if ra == rb, do: {:same, ra}, else: {:differ, ra, rb}
    end
  end

  defp read(%{port: port, name: name} = runner, timeout, acc) do
    receive do
      {^port, {:data, {:eol, chunk}}} -> {:ok, IO.iodata_to_binary(Enum.reverse([chunk | acc]))}
      {^port, {:data, {:noeol, chunk}}} -> read(runner, timeout, [chunk | acc])
      {^port, {:exit_status, s}} -> {:error, "#{name} exited with status #{s}"}
    after
      timeout -> {:error, "#{name} gave no response within #{timeout} ms"}
    end
  end

  @doc "The summary written by `mix r1.diff --report`."
  def summary(result, stats, failure, meta) do
    Map.merge(meta, %{
      "generator_version" => Generator.version(),
      "result" => Atom.to_string(result),
      "requests" => stats.requests,
      "fn_counts" => stats.fns,
      "length_histogram" => Map.new(stats.lengths, fn {k, v} -> {Integer.to_string(k), v} end),
      "failure" => failure
    })
  end

  def encode(summary), do: Canonical.encode(summary)
end
