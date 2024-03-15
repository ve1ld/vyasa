defmodule Vyasa.Corpus.Migrator.Dump do
  alias Vyasa.Repo

  def table(mod) do
    Code.ensure_loaded?(mod)
    assoc = mod.__schema__(:associations)
    mod
    |> Repo.all()
    |> Repo.preload(assoc)
    |> Enum.map(fn r ->
      r
      |> hydrate_voices()
    end)
    |> Enum.map(&process_struct/1)
    |> Jason.encode!()
  end

  def save(mod) do
    Path.expand("#{mod}/#{System.os_time}.json", "data")
    |> tap(&File.mkdir_p!(Path.dirname(&1)))
    |> File.open!([:write])
    |> IO.binwrite(table(mod))
  end

  # if voices being dumped need to have a media dump
  def hydrate_voices(%{voices: [_v | _] = voices} = record) do
    voices
    |> Repo.preload(:video)
    |> Vyasa.Medium.Store.hydrate()
    |> Enum.map(&Vyasa.Medium.Store.download(&1))
    %{record | voices: voices}
  end

  def hydrate_voices(r), do: r

  defp process_struct(%{__struct__: struct} = s) do
    associations = struct.__schema__(:associations)
    s
    |> Map.from_struct()
    |> Enum.map(&process_field(associations, &1))
    |> Enum.reject(fn {_k,v} -> is_nil(v) end)
    |> Enum.into(%{})

  end

  defp process_field(associations, {k, v}) when is_list(v) and is_struct(hd(v)) do
    if k in associations do
      {k, Enum.map(v, &process_struct/1)}
    else
      {k, v}
    end
  end

  defp process_field(_associations, {k, %Ecto.Association.NotLoaded{}}) do
    {k, nil}
  end

  defp process_field(_associations, {:__meta__, _}) do
    {:reject, nil}
  end

  defp process_field(_associations, {k, %DateTime{} = d}) do
    {k, d}
  end

  defp process_field(associations, {k, v}) when is_struct(v) do
    if k in associations do
      {k, process_struct(v)}
    else
      {k, Map.from_struct(v)}
    end
  end

  defp process_field(_associations, {k, v}), do: {k, v}

end
