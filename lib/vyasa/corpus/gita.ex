defmodule Vyasa.Corpus.Gita do

  @verse Path.join(:code.priv_dir(:vyasa), "static/corpus/gita/verse.json")
  |> tap(&(@external_resource &1))
  |> File.read!()
  |> Jason.decode!()

  def verses(chapter_no) when is_integer(chapter_no) do
    verses = @verse[to_string(chapter_no)]
  end
  def verses(_), do: []

end
