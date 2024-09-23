defmodule VyasaWeb.Hook.UserAgent do
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    case Phoenix.LiveView.get_connect_info(socket, :user_agent) do
      user_agent when is_binary(user_agent) ->
        device_type = Vyasa.Parser.UserAgent.parse_user_agent(user_agent)
        {:cont, assign(socket, device_type: device_type)}

      _ ->
        {:cont, assign(socket, device_type: :unknown)}
    end
  end
end
