defmodule Vyasa.Corpus.Engine.Shlokam do
  @url "https://shlokam.org/"
  alias Vyasa.Corpus.Engine.Fallback

  def run(path, opts \\ []) do
    #storage opts
    @url
    |> fetch_tree(path)
    |> scrape()
    |> store(path, Keyword.get(opts, :o, nil))
  end

  def fetch_tree(url, path \\ "") do
    case Req.get!(url <> path, connect_options: [transport_opts: [cacerts: :public_key.cacerts_get()]]) do
      %{body: body} ->
        {:ok, body
        |> Floki.parse_document!()
        |> Floki.find(".uncode_text_column")}
      %{status: 301, headers: header} ->
        header
        |> Keyword.get(:location)
        |> fetch_tree()

      error ->
        IO.inspect(error, label: :primary_site_err)
        Fallback.run(url <> path)
    end
  end

  defp scrape({:ok, tree}) do
    tree
    |> Enum.reduce(%{title: nil, description: nil, verses: []}, fn
      {"div", _, [{"h3", [], ["Description"]} | para]}, acc ->
        # IO.inspect(rem, label: "div")
        desc =
        para
        |> Floki.text()

      %{acc | description: desc}

    {"div", _, [{"h3", _, _} = h3_tree]}, acc ->
        title =
        h3_tree
        |> Floki.text()

      %{acc | title: title}

    {"div", _, [{"div", [{"class", "verse_sanskrit"}], _verse} | _] = verse_tree}, acc ->
        [curr | [%{"count" => count} | _] = verses] =
        Enum.reduce(verse_tree, [], fn
        # n case verse break
        {"hr", [{"class", "verse_separator"}], []}, [curr | [%{"count" =>  c} | _] = acc] ->
            [Map.put(curr, "count", c + 1) | acc]

          # init verse break
          {"hr", [{"class", "verse_separator"}], []}, [curr | acc] ->
            [Map.put(curr, "count", 1) | acc]

          # n case after verse break
          {"div", [{"class", class}], _} = c_tree, [%{"count" => _} | _] = acc ->
            [%{class => c_tree |> Floki.text()} | acc]

          # n case before verse break
          {"div", [{"class", class}], _} = c_tree, [curr | acc]  when is_map(curr)->
            [Map.put(curr, class, c_tree |> Floki.text()) | acc]

          # init
          {"div", [{"class", class}], _} = c_tree, [] ->
            [%{class => c_tree |> Floki.text()}]

          others, acc ->
            IO.inspect(others)
          acc
        end)

      #formatting & tying loose ends
      clean_verses = [Map.put(curr, "count", count + 1)| verses]
      |>  Enum.reverse()

      %{acc | verses: clean_verses}

      _, acc ->
        acc
    end)
  end

  defp scrape(err), do: err

  def store(_text, _tree, "db") do
    # TODO parsing logic into text indexer structs and db insert ops
  end

  def store(tree, text, nil) do
    # TODO parsing logic into text indexer structs and db insert ops
    json = Jason.encode!(tree)
    Application.app_dir(:vyasa, "priv")
    |> Path.join("/static/corpus/shlokam.org/#{text}.json")
    |> tap(&File.touch(&1))
    |> tap(&File.write!(&1, json))
  end

  def store(tree, text, file_path) do
    # TODO parsing logic into text indexer structs and db insert ops
    json = Jason.encode!(tree)
    file_path
    |> Path.join("/shlokam.org")
    |> tap(&File.mkdir(&1))
    |> Path.join("/#{text}.json")
    |> tap(&File.touch(&1))
    |> tap(&File.write!(&1, json))
  end



 end
