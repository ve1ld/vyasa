defmodule VyasaCLI do
  def main(args \\ []) do
    IO.inspect(args)

    args
    |> parse_args()
    |> response()
    |> IO.puts()
  end

  defp parse_args([command | ["--" <> _] = args]) do
    {opts, _, _} =
      args
      |> OptionParser.parse(switches: [storage: :string])

    {command, opts}
  end

  defp parse_args([command | [arg | _] = args]) do
    {opts, _, _} =
      args
      |> OptionParser.parse(switches: [o: :string, path: :string])

    {command, arg, opts}
  end

  defp response({"fetch", "shlokam.org/" <> path, opts}) do
    Vyasa.Corpus.Engine.Shlokam.run(path, opts)
  end

  defp response({"fetch", _, _}) do
    "Unsupported domain
  Try one of the following:
  shlokam.org/
  "
  end

  defp response(_) do
    "Command doesnt belong to us "
  end
end
