defmodule Vyasa.Corpus.Engine.Fallback do
  @url "https://archive.org/wayback/available?url="

  def run(path) do
    #storage opts
    @url
    |> fetch_url(path)
    |> fetch_tree()

  end

  def fetch_url(url, path \\ "") do
    case Req.get(url <> path) do
      {:ok, %{body: %{"archived_snapshots" =>
                       %{"closest" =>
                          %{"url" => url}}}}} ->
        {:ok, url}
      {:ok, %{body: %{"archived_snapshots" => %{}}}} ->
        IO.inspect("Not Found", label: :fallback_err)
        {:err, :not_found}
      {:error, reason} ->
        IO.inspect(reason, label: :fallback_err)
        {:err, :fallback_failed}
    end
  end

  def fetch_tree({:ok, url}), do: Req.get!(url).body
  def fetch_tree(err), do: err

end
