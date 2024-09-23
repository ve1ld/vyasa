defmodule Vyasa.Corpus.Engine.Fallback do
  @url "https://archive.org/wayback/available?url="

  def run(path) do
    # storage opts
    @url
    |> fetch_url(path)
    |> IO.inspect()
    |> fetch_tree()
  end

  def fetch_url(url, path \\ "") do
    case Req.get(url <> path, conn_opts()) do
      {:ok, %{body: %{"archived_snapshots" => %{"closest" => %{"url" => url}}}}} ->
        {:ok, url}

      {:ok, %{body: %{"archived_snapshots" => %{}}}} ->
        IO.inspect("Not Found", label: :fallback_err)
        {:err, :not_found}

      {:error, reason} ->
        IO.inspect(reason, label: :fallback_err)
        {:err, :fallback_failed}
    end
  end

  def fetch_tree({:ok, url}) do
    url
    |> to_https()
    |> Req.get!(conn_opts())
    |> Map.get(:body)
  end

  def fetch_tree(err), do: err

  defp to_https(url) do
    url
    |> URI.parse()
    |> Map.put(:port, nil)
    |> Map.put(:scheme, "https")
    |> URI.to_string()
  end

  defp conn_opts(), do: [connect_options: [transport_opts: [cacerts: :public_key.cacerts_get()]]]
end
