defmodule VyasaWeb.Admin.Written.Verse do
    use LiveAdmin.Resource, schema: Vyasa.Written.Verse
end

defmodule VyasaWeb.Admin.Medium.Event do
  use LiveAdmin.Resource, schema: Vyasa.Medium.Event,
    immutable_fields: [:source_id],
    actions: [:silence, :next, :prev],
    render_with: :render_field



  def render_field(record, field, session) do
    VyasaWeb.Admin.Renderer.render_field(record, field, session)
  end


  def silence(%{voice: _v} = e, _sess) do
    e = %{e | voice: nil}
    {:ok, e}
  end

  def next(%{voice: _v} = e, _sess) do
    {:ok, Vyasa.Medium.get_event_by_order!(e, 1)}
  end

  def prev(%{voice: _v} = e, _sess) do
    {:ok, Vyasa.Medium.get_event_by_order!(e, -1)}
  end
end


defmodule VyasaWeb.Admin.Renderer do
  use Phoenix.Component

  def render_field(%{origin: o, voice: %Vyasa.Medium.Voice{} = v} = assigns, :phase, _session) do
    assigns = %{assigns | origin: floor(o/1000), voice: Vyasa.Medium.Store.hydrate(v)}
  ~H"""
  <%= @phase %>
  <audio id={"#{@origin}-audioplayback"} controls preload="metadata">
    <source src={@voice.file_path <> "#t=#{@origin}"} type="audio/mp3">
  </audio>
  """
  end

  def render_field(%{verse: %Vyasa.Written.Verse{} = v} = assigns, :verse_id, _session) do
    assigns = %{assigns | verse: v |> Vyasa.Repo.preload(:translations)}
    ~H"""
  <div class="flex items-center justify-center">
  <%= @verse.body %>
  </div>
  <div class="whitespace-pre-line">
  <%= List.first(@verse.translations).target.body_translit %>
  </div>
  """
  end


  def render_field(record, field, _session) do
    IO.inspect(field)
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
