defmodule VyasaWeb.ModeLive.Mediator do
  @moduledoc """
  In relation to the behavioural pattern of a Mediator (ref: https://refactoring.guru/design-patterns/mediator),
  This mediator is intended to restrict what the mode-specific components can do.

  It shall maintain state that is mode-agnostic, such as the current mode, url_params and ui_state
  and any mode-specific actions shall be deferred to the modules that are slotted in (and defined statically at the user_mode module).
  """
  use VyasaWeb, :live_view
  alias VyasaWeb.ModeLive.{UserMode, UiState}
  alias Vyasa.{Draft}
  alias Phoenix.LiveView.Socket
  alias VyasaWeb.Session
  alias Vyasa.Sangh
  @supported_modes UserMode.supported_modes()

  @mod_registry %{"UiState" => UiState}

  @impl true
  def mount(_params, _sess, socket) do
    # TODO: this needs to parse mode from the url, the router needs to be updated also.
    %UserMode{
      default_ui_state: %UiState{} = initial_ui_state
    } = mode = UserMode.get_initial_mode()

    {
      :ok,
      socket
      |> assign(mode: mode)
      |> assign(url_params: nil)
      |> assign(ui_state: initial_ui_state),
      layout: {VyasaWeb.Layouts, :display_manager}
    }
  end

  @impl true

  def handle_params(params, url, socket) do
    url_params = params |> Map.put(:path, URI.parse(url).path)

    {:noreply,
     socket
     |> assign(url_params: url_params)
     |> maybe_inject_mode()
     |> maybe_focus_binding()
     |> sync_session()}
  end

  # injects mode if url slug contains mode, and there's an existing mode in socket state
  defp maybe_inject_mode(
         %{
           assigns: %{
             url_params: %{path: path},
             mode: %UserMode{mode: curr_mode}
           }
         } = socket
       )
       when is_binary(path) do
    injected_mode =
      path
      |> String.split("/")
      |> Enum.at(1)

    case injected_mode in @supported_modes do
      true ->
        socket
        |> change_mode(curr_mode, injected_mode)

      _ ->
        socket
    end
  end

  # injects mode from url slug, when there's no existing loaded mode in the socket state
  defp maybe_inject_mode(
         %{
           assigns: %{
             url_params: %{path: path}
           }
         } = socket
       )
       when is_binary(path) do
    injected_mode =
      path
      |> String.split("/")
      |> Enum.at(1)

    case injected_mode in @supported_modes do
      true ->
        socket
        |> assign(:mode, UserMode.get_mode(injected_mode))

      _ ->
        socket
    end
  end

  defp maybe_inject_mode(socket) do
    socket
  end

  defp maybe_focus_binding(
         %{
           assigns: %{
             url_params: %{"bind" => bind_id},
             mode: %UserMode{
               mode_context_component: component,
               mode_context_component_selector: selector
             }
           }
         } = socket
       ) do
    bind = Draft.get_binding!(bind_id)
    send_update(component, id: selector, binding: bind)

    socket
    |> UiState.assign(:focused_binding, bind)
  end

  defp maybe_focus_binding(socket) do
    socket
  end

  defp sync_session(
         %{assigns: %{session: %Session{id: id, sangh: %{id: sangh_id}} = sess}} = socket
       )
       when is_binary(id) and is_binary(sangh_id) do
    # currently needs name prerequisite to save
    socket
    |> push_event("initSession", sess)
  end

  defp sync_session(%{assigns: %{session: %Session{id: id} = sess}} = socket)
       when is_binary(id) do
    # initialises sangh if uninitiated (didnt init at Vyasa.Session)
    {:ok, sangh} = Sangh.create_session()
    sangh_sess = %{sess | sangh: sangh}

    socket
    |> assign(session: sangh_sess)
    |> push_event("initSession", sangh_sess)
  end

  defp sync_session(socket) do
    socket
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

  def handle_event(
        "name",
        %{"name" => name},
        %{assigns: %{session: sess}} = socket
      ) do
    {:noreply,
     socket
     |> assign(session: %{sess | name: name})
     |> sync_session()}
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

  def handle_event(
        "bind::to",
        %{"binding" => bind},
        %Socket{
          assigns: %{
            mode: %UserMode{
              mode_context_component: component,
              mode_context_component_selector: selector
            }
          }
        } = socket
      ) do
    {:ok, bind} = Draft.bind_node(bind)
    # pass binding contexts to the current mode and drafting reflector
    send_update(component, id: selector, binding: bind)
    # TODO: implement nav_event handlers from action bar
    # This is also the event handler that needs to be triggerred if the user clicks on the nav buttons on the media bridge.
    {:noreply, socket |> UiState.assign(:focused_binding, bind)}
  end

  def handle_event(
        "bind::share",
        _,
        %Socket{
          assigns: %{
            ui_state: %UiState{focused_binding: bind},
            url_params: %{path: path}
          }
        } = socket
      ) do
    {:ok, shared_bind} =
      bind
      |> Draft.create_binding()

    IO.inspect(socket.assigns.url_params)

    {:noreply,
     socket
     |> push_event("bind::share", %{url: unverified_url(socket, "#{path}", bind: shared_bind.id)})
     |> put_flash(:info, "binded to your clipboard")}
  end

  def handle_event(event, message, socket) do
    IO.inspect(%{event: event, message: message}, label: "pokemon")
    {:noreply, socket}
  end

  @impl true
  @doc """
  TODO: update this doc after handling handshakes better
  Handles the custom message that corresponds to the :media_handshake event with the :init
  message, regardless of the module that dispatched the message.

  This indicates an intention to sync the media library with the chapter, hence it
  returns a message containing %Voice{} info that can be used to generate a playback struct.
  """
  def handle_info(
        {_, :media_handshake, :init} = _msg,
        %{
          assigns: %{
            mode: %UserMode{
              mode_context_component: component,
              mode_context_component_selector: selector
            }
          }
        } = socket
      ) do
    send_update(component, id: selector, event: :media_handshake)

    {:noreply, socket}
  end

  @impl true
  def handle_info({"mutate_" <> mod, function_name, args}, socket)
      when is_binary(function_name) and is_list(args) do
    with :ok <- validate_function_name(function_name, @mod_registry[mod]) do
      func = String.to_existing_atom(function_name)
      updated_socket = apply(@mod_registry[mod], func, [socket | args])
      {:noreply, updated_socket}
    else
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(msg, socket) do
    IO.inspect(msg, label: "[fallback clause] unexpected message in ModeLive.Mediator")
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
