defmodule VyasaWeb.ModeLive.UiState do
  @moduledoc """
  UiState defines booleans and other UI-related aspects that need to be tracked.
  This shall only be a struct definition. If mediating state transitions becomes complex enough, then we shall
  add split DM to a UiStateManager and DataManager or something of that nature.

  This is expected to be used in 2 ways:
  1. allow DM to manage this UiState via this struct
  2. allow UserModes to be defined with an initial UI state in mind
  """
  alias Phoenix.LiveView.Socket
  alias VyasaWeb.ModeLive.UiState
  import Phoenix.VerifiedRoutes
  @endpoint VyasaWeb.Endpoint
  @router VyasaWeb.Router

  import Phoenix.Component, only: [assign: 2]

  defstruct [
    :show_media_bridge?,
    :show_action_bar?,
    :focused_binding
  ]

  defp set_hide_media_bridge(%UiState{} = state) do
    %UiState{state | show_media_bridge?: false}
  end

  defp set_show_media_bridge(%UiState{} = state) do
    %UiState{state | show_media_bridge?: true}
  end


  def assign(
        %{assigns: %{ui_state: curr_state}} = socket,
        attr,
        assignment
      ) do

      socket |> assign(ui_state: %{curr_state | attr => assignment})
  end

  def update_media_bridge_visibility(
        %Socket{
          assigns: %{
            device_type: device_type,
            ui_state: ui_state
          }
        } = socket,
        is_focusing_on_input?
      )
      when is_boolean(is_focusing_on_input?) do
    case should_show_media_bridge(device_type, is_focusing_on_input?) do
      true ->
        socket
        |> assign(ui_state: set_show_media_bridge(ui_state))

      false ->
        socket |> assign(ui_state: set_hide_media_bridge(ui_state))
    end
  end

  @doc """
  Changes UI struct to hide the media_bridge. The ui_state must be within the socket.
  """
  def hide_media_bridge(
        %Socket{
          assigns: %{
            ui_state: %UiState{} = ui_state
          }
        } = socket
      ) do
    socket
    |> assign(
      ui_state:
        ui_state
        |> set_hide_media_bridge()
    )
  end

  defp should_show_media_bridge(device_type, is_focusing_on_input?)
       when is_atom(device_type) and is_boolean(is_focusing_on_input?) do
    case {device_type, is_focusing_on_input?} do
      {:mobile, true} -> false
      {:mobile, false} -> true
      {_, _} -> true
    end
  end

  defp should_show_media_bridge(_, _) do
    true
  end




  def update_emphasis(socket, %{verse_id: verse_id}) do

    socket
    |> maybe_navigate_next(verse_id)
    |> Phoenix.LiveView.push_event("verseEmphasis", %{verseId: verse_id, className: "emphasized-verse"})
  end

  defp maybe_navigate_next(%{assigns: %{url_params: %{"chap_no" => prev_chap_no, "source_title" => prev_st}}} = socket, verse_id) do
    %{chapter_no: chap_no, source: %{title: st}} = Vyasa.Written.get_verse!(verse_id)
    if chap_no !== prev_chap_no || st !== prev_st do
      socket
      |> Phoenix.LiveView.push_patch(to: ~p"/explore/#{st}/#{chap_no}/")
    else
      socket
    end
  end

  defp maybe_navigate_next(socket, _) do
    socket
  end
end
