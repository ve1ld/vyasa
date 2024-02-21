defmodule VyasaWeb.Admin.Written.Verse do
    use LiveAdmin.Resource, schema: Vyasa.Written.Verse
end

defmodule VyasaWeb.Admin.Medium.Event do
  use LiveAdmin.Resource, schema: Vyasa.Medium.Event, immutable_fields: [:source_id], actions: [:call], render_with: :render_field

  def render_field(%{voice: v} = e, :phase, _session) do
    VyasaWeb.Admin.Renderer.render_link(%{e | voice: Vyasa.Medium.Store.hydrate(v)})
  end

  def render_field(record, field, session) do
    VyasaWeb.Admin.Renderer.render_field(record, field, session)
  end


  def call(%{voice: v}, _sess) do
    IO.inspect(v)
    {:ok, v}
  end
end


defmodule VyasaWeb.Admin.Renderer do
  use Phoenix.Component

  def render_link(%{origin: o, voice: %{file_path: _fp}} = assigns) do
    assigns = %{assigns | origin: floor(o/1000)}
  ~H"""
  <%= @phase %>
  <audio controls>
    <source src={@voice.file_path <> "#t=#{@origin}"} type="audio/mp3">
  </audio>
  """
  end

  def render_field(record, field, _session) do
    record
    |> Map.fetch!(field)
    |> case do
      bool when is_boolean(bool) ->
        if bool, do: "Yes", else: "No"
      date = %Date{} ->
        Calendar.strftime(date, "%a, %B %d %Y")
      bin when is_binary(bin) -> bin
      _ ->
        record
        |> Map.fetch!(field)
        |> case do
          val when is_binary(val) -> val
          val -> inspect(val, pretty: true)
        end
    end
  end

end
