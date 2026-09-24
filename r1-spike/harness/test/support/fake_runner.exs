# Fake runner for harness self-tests: echoes each request line. With
# `--corrupt-step N`, a world.run with more than N commands gets a changed response,
# so the minimal failing input has exactly N + 1 commands.
corrupt =
  case System.argv() do
    ["--corrupt-step", n] -> String.to_integer(n)
    [] -> nil
  end

Stream.repeatedly(fn -> IO.read(:stdio, :line) end)
|> Stream.take_while(&is_binary/1)
|> Enum.each(fn line ->
  line = String.trim_trailing(line, "\n")

  out =
    with n when is_integer(n) <- corrupt,
         {:ok, %{"fn" => "world.run", "commands" => cmds}} when length(cmds) > n <-
           JSON.decode(line) do
      "corrupt:" <> line
    else
      _ -> line
    end

  IO.write(out <> "\n")
end)
