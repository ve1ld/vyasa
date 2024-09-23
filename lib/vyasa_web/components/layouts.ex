defmodule VyasaWeb.Layouts do
  use VyasaWeb, :html

  embed_templates "layouts/*"

  attr(:contents, :map, required: true)

  @doc """
  Function component into which meta tags can be inserted.
  """
  def meta_tags(assigns) do
    ~H"""
    <meta :for={{name, value} <- parse_contents(@contents)} property={name} content={value} />
    """
  end

  defp parse_contents(contents) when is_map(contents) do
    IO.puts("Contents map for meta contents:")
    IO.inspect(contents)

    contents
    |> Enum.map(&define_name/1)
    |> List.flatten()
    |> Enum.into(%{})
  end

  defp parse_contents(_contents), do: %{}

  defp define_name({k, v}) when is_map(v) do
    Enum.map(v, &define_name(&1, k))
  end

  defp define_name(data), do: define_name(data, "og")
  defp define_name({k, v}, prefix), do: {"#{prefix}:#{k}", v}
end
