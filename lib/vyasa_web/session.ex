defmodule VyasaWeb.Session do
  import Phoenix.Component, only: [assign: 2]
  import Phoenix.LiveView, only: [get_connect_params: 1]

  @derive Jason.Encoder
  defstruct name: nil, id: nil, active: true, sangh_id: Ecto.UUID.generate(), last_opened: DateTime.now!("Etc/UTC")

  @default_locale "en"
  @timezone "UTC"
  @timezone_offset 0

  def on_mount(:sangh, params, _sessions, socket) do
    # get_connect_params returns nil on the first (static rendering) mount call, and has the added connect params from the js LiveSocket creation on the subsequent (LiveSocket) call
    #
    {:cont,
     socket
     |> assign(
     locale: get_connect_params(socket)["locale"] || @default_locale,
     tz: %{timezone: get_connect_params(socket)["timezone"] || @timezone,
           timezone_offset: get_connect_params(socket)["timezone_offset"] || @timezone_offset},
     session: get_connect_params(socket)["session"] |> mutate_session(params)
     )}
  end

  defp mutate_session(%{"id" => id} = sess, %{"s" => s_id}) when is_binary(id) and is_binary(s_id)do
    atomised_sess = for {key, val} <- sess, into: %{} do
      {String.to_existing_atom(key), val}
    end
    %{struct(%__MODULE__{}, atomised_sess ) | sangh_id: s_id}
  end

  # careful of client and server state race. id here is not SOT
  defp mutate_session(%{"id" => id} = sess, _) when is_binary(id) do
    atomised_sess = for {key, val} <- sess, into: %{} do
      {String.to_existing_atom(key), val}
    end

    IO.inspect(struct(%__MODULE__{}, atomised_sess), label: "wow")
    struct(%__MODULE__{}, atomised_sess)
  end

  # false first load
  defp mutate_session(_, _), do: %__MODULE__{}
  end
