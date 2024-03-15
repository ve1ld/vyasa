defmodule Vyasa.Corpus.Migrator.Restore do
  def read(path) do
    File.read!(path)
    |> Jason.decode!()
  end
end
