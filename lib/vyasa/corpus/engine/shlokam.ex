defmodule Vyasa.Corpus.Engine.Shlokam do
  @url "https://shlokam.org/"

  def run(path, opts \\ []) do
    #storage opts
    path
    |> fetch_tree()
    |> scrape()
    |> store(Keyword.get(opts, :storage, :file))
  end

  def fetch_tree(path) do
    resp = Finch.build(:get, @url <> path) |> Finch.request(Vyasa.Finch)
    resp.body
    |> Floki.parse_document!()
    |> Floki.find(".uncode_text_column")
  end

  defp scrape(tree) do
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

  def store(tree, :file) do
    # TODO parsing logic into text indexer structs and db insert ops
    json = Jason.encode!(tree)
    File.write!("path/to/file.json", json)
    :code.priv_dir(:vyasa) |> Path.join("/static/corpus/shlokam.org/verses.json")
  end

  def store(_tree, :db) do
    # TODO parsing logic into text indexer structs and db insert ops
  end



 end
