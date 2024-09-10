defmodule VyasaWeb.DisplayManager.DisplayLive do
  @moduledoc """
  Testing out nested live_views
  """
  use VyasaWeb, :live_view
  on_mount VyasaWeb.Hook.UserAgentHook
  alias Vyasa.Display.{UserMode, UiState}
  alias Phoenix.LiveView.Socket
  alias VyasaWeb.Content.ReadingContent
  @supported_modes UserMode.supported_modes()

  @impl true
  def mount(_params, sess, socket) do
    %UserMode{
      default_ui_state: %UiState{} = initial_ui_state
    } = mode = UserMode.get_initial_mode()

    {
      :ok,
      socket
      |> assign(stored_session: sess)
      |> assign(mode: mode)
      |> assign(url_params: nil)
      |> assign(ui_state: initial_ui_state),
      layout: {VyasaWeb.Layouts, :display_manager}
    }
  end

  @impl true
  def handle_params(
        params,
        url,
        %Socket{
          assigns: %{
            live_action: live_action
          }
        } = socket
      ) do
    IO.inspect(url, label: "TRACE: handle param url")
    IO.inspect(live_action, label: "TRACE: handle param live_action")

    {
      :noreply,
      socket
      |> assign(url_params: params)
      # | apply_action(live_action, params)
    }
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp change_mode(socket, curr, target)
       when is_binary(curr) and is_binary(target) and target in @supported_modes do
    case curr == target do
      # prevents unnecessary switches
      true ->
        socket

      false ->
        socket
        |> assign(mode: UserMode.get_mode(target))
    end
  end

  defp change_mode(socket, _, _) do
    socket
  end

  @impl true
  def handle_event(
        "change_mode",
        %{
          "current_mode" => current_mode,
          "target_mode" => target_mode
        } = _params,
        socket
      ) do
    {:noreply,
     socket
     |> change_mode(current_mode, target_mode)}
  end

  @impl true
  def handle_event(
        "read" <> "::" <> _event = _nav_event,
        _,
        %Socket{
          assigns: %{
            mode: %UserMode{
              mode: _mode_name
            }
          }
        } = socket
      ) do
    # TODO: implement nav_event handlers from action bar
    # This is also the event handler that needs to be triggerred if the user clicks on the nav buttons on the media bridge.
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "discuss" <> "::" <> event = _nav_event,
        _,
        %Socket{
          assigns: %{
            mode: %UserMode{
              mode: mode_name
            }
          }
        } = socket
      ) do
    IO.inspect(
      %{
        "event" => event,
        "mode" => mode_name
      },
      label: "TRACE: TODO handle nav_event @ action-bar region"
    )

    # TODO: implement nav_event handlers from action bar
    # This is also the event handler that needs to be triggerred if the user clicks on the nav buttons on the media bridge.
    {:noreply, socket}
  end

  def handle_event(event, message, socket) do
    IO.inspect(%{event: event, message: message}, label: "pokemon")
    {:noreply, socket}
  end

  @impl true
  @doc """
  TODO: update this doc
  Handles the custom message that corresponds to the :media_handshake event with the :init
  message, regardless of the module that dispatched the message.

  This indicates an intention to sync the media library with the chapter, hence it
  returns a message containing %Voice{} info that can be used to generate a playback struct.
  """
  def handle_info(
        {_, :media_handshake, :init} = _msg,
        %{
          assigns: %{
            session: %{"id" => sess_id}
          }
        } = socket
      ) do
    # TODO: currently, this is hardcoded to "ReadingContent". At the end of this refactor, we shall
    send_update(ReadingContent, id: "reading-content", sess_id: sess_id)
    {:noreply, socket}
  end

  @impl true
  # this enables the children of DM to allow DM to subscribe to a generic topic.
  # Thereafter, messages sent through that topic, to the DM can be listened to by the DM and
  # the DM can pass that message to the appropriate slotted child component.
  def handle_info(%{"cmd" => :sub_to_topic, "topic" => topic} = _msg, socket) do
    # dbg()
    Vyasa.PubSub.subscribe(topic)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:change_ui, function_name, args}, socket)
      when is_binary(function_name) and is_list(args) do
    with :ok <- validate_function_name(function_name, UiState) do
      func = String.to_existing_atom(function_name)
      updated_socket = apply(UiState, func, [socket | args])
      {:noreply, updated_socket}
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(msg, socket) do
    IO.inspect(msg, label: "[fallback clause] unexpected message in DisplayManager")
    {:noreply, socket}
  end

  # TODO: when it's time, add in the optional default value, left it out to avoid the warning message
  # defp validate_function_name(function_name, module \\ __MODULE__)
  defp validate_function_name(function_name, module)
       when is_binary(function_name) do
    if function_name in get_function_names(module) do
      :ok
    else
      {:error, "Function #{function_name} does not exist."}
    end
  end

  # TODO: add the optional module when it's time
  # defp get_function_names(mod \\ __MODULE__) do
  defp get_function_names(mod) do
    mod.__info__(:functions)
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&Atom.to_string/1)
  end
end
