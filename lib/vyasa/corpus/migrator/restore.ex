defmodule Vyasa.Corpus.Migrator.Restore do
  def read(path) do
    File.read!(path)
    |> Jason.decode!()
  end

  def run(source) do
    source
    |> read()
    |> Enum.map(fn x ->
      t =
        x["translations"]
        |> Enum.group_by(fn m -> {m["type"], m["verse_id"] || m["chapter_no"]} end)

      v =
        x["voices"]
        |> Enum.group_by(fn m -> m["chapter_no"] end)

      %{
        x
        | "chapters" =>
            Enum.map(x["chapters"], fn %{"no" => no} = c ->
              c
              |> Map.put("translations", t[{"chapters", no}])
              |> Map.put(
                "voices",
                (is_list(v[no]) && v[no] |> Enum.map(fn %{"id" => _} = v -> v end)) || []
              )
            end),
          "verses" =>
            Enum.map(x["verses"], fn %{"id" => id} = v ->
              v |> Map.put("translations", t[{"verses", id}])
            end)
      }
    end)
    |> Enum.map(
      &(%Vyasa.Written.Source{}
        |> Vyasa.Written.Source.gen_changeset(&1)
        |> Vyasa.Repo.insert!())
    )

    # events are dependent on both verse and voice
    source
    |> read()
    |> Enum.map(fn x ->
      # &1["translations"]
      x["events"]
      |> Enum.map(&(&1 |> Vyasa.Medium.create_event()))
    end)
  end
end
