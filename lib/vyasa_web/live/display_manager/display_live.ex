defmodule VyasaWeb.DisplayManager.DisplayLive do
  @moduledoc """
  Testing out nested live_views
  """
  use VyasaWeb, :live_view
  alias Vyasa.Display.UserMode
  alias Phoenix.LiveView.Socket
  alias Vyasa.Written
  alias Vyasa.Written.{Chapter}
  @supported_modes UserMode.supported_modes()

  @impl true
  def mount(_params, sess, socket) do
    # encoded_config = Jason.encode!(@default_player_config)
    %UserMode{} = mode = UserMode.get_initial_mode()

    {
      :ok,
      socket
      # to allow passing to children live-views
      |> assign(session: sess)
      |> assign(mode: mode),
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
      socket |> apply_action(live_action, params)
    }
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp apply_action(%Socket{} = socket, :show_sources, _params) do
    IO.inspect(:show_sources, label: "TRACE: apply action DM action show_sources:")
    # IO.inspect(params, label: "TRACE: apply action DM params:")

    # TODO: make this into a live component
    socket
    |> stream(:sources, Written.list_sources())
    |> assign(:content_action, :show_sources)
    |> assign(:page_title, "Sources")
    |> assign(:meta, %{
      title: "Sources to Explore",
      description: "Explore the wealth of indic knowledge, distilled into words.",
      type: "website",
      image: url(~p"/images/the_vyasa_project_1.png"),
      url: url(socket, ~p"/explore/")
    })
  end

  # TODO: change navigate -> patch on the html side
  defp apply_action(
         %Socket{} = socket,
         :show_chapters,
         %{"source_title" => source_title} =
           params
       ) do
    IO.inspect(:show_chapters, label: "TRACE: apply action DM action show_chapters:")
    IO.inspect(params, label: "TRACE: apply action DM params:")
    IO.inspect(source_title, label: "TRACE: apply action DM params source_title:")

    [%Chapter{source: src} | _] = chapters = Written.get_chapters_by_src(source_title)

    socket
    |> assign(:content_action, :show_chapters)
    |> assign(:page_title, to_title_case(src.title))
    |> assign(:source, src)
    |> assign(:meta, %{
      title: to_title_case(src.title),
      description: "Explore the #{to_title_case(src.title)}",
      type: "website",
      image: url(~p"/og/#{VyasaWeb.OgImageController.get_by_binding(%{source: src})}"),
      url: url(socket, ~p"/explore/#{src.title}")
    })
    |> stream_configure(:chapters, dom_id: &"Chapter-#{&1.no}")
    |> stream(:chapters, chapters |> Enum.sort_by(fn chap -> chap.no end))

    # |> dbg()
  end

  defp apply_action(
         %Socket{} = socket,
         :show_verses,
         %{"source_title" => source_title, "chap_no" => chap_no} = params
       ) do
    IO.inspect(:show_verses, label: "TRACE: apply action DM action show_verses:")
    IO.inspect(params, label: "TRACE: apply action DM params:")
    IO.inspect(source_title, label: "TRACE: apply action DM params source_title:")
    IO.inspect(chap_no, label: "TRACE: apply action DM params chap_no:")
    socket
  end

  defp apply_action(%Socket{} = socket, _, _) do
    socket
  end

  defp apply_action(socket, action, params) do
    IO.inspect(action, label: "TRACE: apply action DM action:")
    IO.inspect(params, label: "TRACE: apply action DM params:")

    socket
    |> assign(:page_title, "Sources")
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

  defp change_mode(socket, curr, target)
       when is_binary(curr) and is_binary(target) and target in @supported_modes do
    socket
    |> assign(mode: UserMode.get_mode(target))
  end

  defp change_mode(socket, _, _) do
    socket
  end
end
