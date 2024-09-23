defmodule VyasaWeb.DisplayManager.DisplayLive do
  @moduledoc """
  Testing out nested live_views
  """
  use VyasaWeb, :live_view

  on_mount VyasaWeb.Hook.UserAgentHook

  alias Vyasa.Display.UserMode
  alias VyasaWeb.OgImageController
  alias Phoenix.LiveView.Socket
  alias Vyasa.{Medium, Written, Draft}
  alias Vyasa.Medium.{Voice}
  alias Vyasa.Written.{Source, Chapter}
  alias Vyasa.Sangh.{Comment, Mark}

  @supported_modes UserMode.supported_modes()
  @default_lang "en"
  @default_voice_lang "sa"

  @impl true
  def mount(_params, sess, socket) do
    # encoded_config = Jason.encode!(@default_player_config)

    %UserMode{
      # TEMP
      show_media_bridge_default?: show_media_bridge_default?
    } = mode = UserMode.get_initial_mode()

    {
      :ok,
      socket
      # to allow passing to children live-views
      # TODO: figure out if this is important
      |> assign(stored_session: sess)
      |> assign(mode: mode)
      |> assign(show_action_bar?: true)
      |> assign(show_media_bridge?: show_media_bridge_default?),
      # temp
      # |> assign(show_media_bridge?: true),

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
    |> maybe_stream_configure(:chapters, dom_id: &"Chapter-#{&1.no}")
    |> stream(:chapters, chapters |> Enum.sort_by(fn chap -> chap.no end))
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

    with %Source{id: sid} = source <- Written.get_source_by_title(source_title),
         %{verses: verses, translations: [ts | _], title: chap_title, body: chap_body} = chap <-
           Written.get_chapter(chap_no, sid, @default_lang) do
      fmted_title = to_title_case(source.title)

      IO.inspect(fmted_title, label: "TRACE: am i WITH it?")

      socket
      |> sync_session()
      |> assign(:content_action, :show_verses)
      |> maybe_stream_configure(:verses, dom_id: &"verse-#{&1.id}")
      |> stream(:verses, verses)
      |> assign(
        :kv_verses,
        # creates a map of verse_id_to_verses
        Enum.into(
          verses,
          %{},
          &{&1.id,
           %{
             &1
             | comments: [
                 %Comment{signature: "Pope", body: "Achilles’ wrath, to Greece the direful spring
              Of woes unnumber’d, heavenly goddess, sing"}
               ]
           }}
        )
      )
      |> assign(:marks, [%Mark{state: :draft, order: 0}])
      # DEPRECATED
      # RENAME?
      |> assign(:src, source)
      |> assign(:lang, @default_lang)
      |> assign(:chap, chap)
      |> assign(:selected_transl, ts)
      |> assign(:page_title, "#{fmted_title} Chapter #{chap_no} | #{chap_title}")
      |> assign(:meta, %{
        title: "#{fmted_title} Chapter #{chap_no} | #{chap_title}",
        description: chap_body,
        type: "website",
        image: url(~p"/og/#{OgImageController.get_by_binding(%{chapter: chap, source: source})}"),
        url: url(socket, ~p"/explore/#{source.title}/#{chap_no}")
      })
    else
      _ ->
        raise VyasaWeb.ErrorHTML.FourOFour, message: "Chapter not Found"
    end
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

  defp sync_session(%{assigns: %{session: %{"id" => sess_id}}} = socket) do
    # written channel for reading and media channel for writing to media bridge and to player
    Vyasa.PubSub.subscribe("written:session:" <> sess_id)
    Vyasa.PubSub.publish(:init, :written_handshake, "media:session:" <> sess_id)

    IO.inspect(sess_id, label: "TRACE: synced the sess with session id: ")
    socket
  end

  defp sync_session(socket) do
    IO.inspect(socket, label: "TRACE: NO SYNC OF SESSION!")
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
  @doc """
  events

  "clickVersetoSeek" ->
  Handles the action of clicking to seek by emitting the verse_id to the live player
  via the pubsub system.

  "binding"
  """
  def handle_event(
        "clickVerseToSeek",
        %{"verse_id" => verse_id} = _payload,
        %{assigns: %{session: %{"id" => sess_id}}} = socket
      ) do
    IO.inspect("handle_event::clickVerseToSeek", label: "checkpoint")
    Vyasa.PubSub.publish(%{verse_id: verse_id}, :playback_sync, "media:session:" <> sess_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{
          assigns: %{
            kv_verses: verses,
            marks: [%Mark{state: :draft, verse_id: curr_verse_id} = d_mark | marks]
          }
        } = socket
      )
      when is_binary(curr_verse_id) and verse_id != curr_verse_id do
    # binding here blocks the stream from appending to quote
    bind = Draft.bind_node(bind)

    bound_verses = verses
       |> then(&put_in(&1[verse_id].binding, bind))
       |> then(&put_in(&1[curr_verse_id].binding, nil))

    {:noreply,
     socket
     |> mutate_verses(curr_verse_id, bound_verses)
     |> mutate_verses(verse_id, bound_verses)

     |> assign(:marks, [%{d_mark | binding: bind, verse_id: verse_id} | marks])}
  end

  # already in mark in drafting state, remember to late bind binding => with a fn()
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind_target_payload = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do
    # binding here blocks the stream from appending to quote
    bind = Draft.bind_node(bind_target_payload)
    bound_verses = put_in(verses[verse_id].binding, bind)

    {:noreply,
     socket
     |> mutate_verses(verse_id, bound_verses)

     |> assign(:marks, [%{d_mark | binding: bind, verse_id: verse_id} | marks])}
  end

  @impl true
  def handle_event(
        "bindHoveRune",
        %{"binding" => bind = %{"verse_id" => verse_id}},
        %{assigns: %{kv_verses: verses, marks: [%Mark{order: no} | _] = marks}} = socket
      ) do
    bind = Draft.bind_node(bind)

    bound_verses = put_in(verses[verse_id].binding, bind)

    {:noreply,
     socket
     |> mutate_verses(verse_id, bound_verses)
     |> assign(:marks, [
       %Mark{state: :draft, order: no + 1, verse_id: verse_id, binding: bind} | marks
     ])}
  end

  @impl true
  def handle_event(
        "verses::focus_toggle_on_quick_mark_drafting",
        %{"key" => "Enter"} = _payload,
        %Socket{
          assigns: %{
            device_type: device_type
          }
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(show_media_bridge?: should_show_media_bridge(device_type, false))}
  end

  @impl true
  def handle_event(
        "verses::focus_toggle_on_quick_mark_drafting",
        %{"is_focusing?" => is_focusing?} = _payload,
        %Socket{
          assigns: %{
            device_type: device_type
          }
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(show_media_bridge?: should_show_media_bridge(device_type, is_focusing?))}
  end

  @impl true
  def handle_event(

        "read" <> "::" <> event = _nav_event,
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

  @impl true
  def handle_event(
        "draft" <> "::" <> event = _nav_event,
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


  @impl true
  def handle_event(

        "markQuote",
        _,
        %{assigns: %{marks: [%Mark{state: :draft} = d_mark | marks]}} = socket
      ) do

    {:noreply, socket |> assign(:marks, [%{d_mark | state: :live} | marks])}
  end

  @impl true

  def handle_event("markQuote", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "createMark",
        %{"body" => body},
        %{assigns: %{kv_verses: verses,
                     marks: [%Mark{state: :draft, verse_id: v_id, binding: binding} = d_mark | marks],
                     device_type: device_type}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:marks, [%{d_mark | body: body, state: :live} | marks])
     |> stream_insert(
       :verses, %{verses[v_id] | binding: binding}
     )
     |> assign(:show_media_bridge?, should_show_media_bridge(device_type, false))}
  end

  # when user remains on the the same binding
  def handle_event(
        "createMark",
        %{"body" => body},
        %{assigns: %{kv_verses: verses,
                     marks: [%Mark{state: :live, verse_id: v_id, binding: binding} = d_mark | _] = marks,
                     device_type: device_type}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:marks, [%{d_mark | body: body, state: :live} | marks])
     |> stream_insert(
       :verses, %{verses[v_id] | binding: binding}
     )
     |> assign(:show_media_bridge?, should_show_media_bridge(device_type, false))}
  end

  @impl true
  def handle_event(
        "createMark",
        _event,
        %Socket{
          assigns: %{
            device_type: device_type
          }
        } =
          socket
      ) do

    {
      :noreply,
      socket
      |> assign(:show_media_bridge?, should_show_media_bridge(device_type, false))
    }

  end

  def handle_event(event, message, socket) do
    IO.inspect(%{event: event, message: message}, label: "pokemon")
    {:noreply, socket}
  end

  # CHECKPOINT: handle_info functions in DM
  @doc """
  Handles the custom message that corresponds to the :media_handshake event with the :init
  message, regardless of the module that dispatched the message.

  This indicates an intention to sync the media library with the chapter, hence it
  returns a message containing %Voice{} info that can be used to generate a playback struct.
  """
  @impl true
  def handle_info(
        {_, :media_handshake, :init} = _msg,
        %{
          assigns: %{
            session: %{"id" => sess_id},
            chap: %Chapter{no: c_no, source_id: src_id}
          }
        } = socket
      ) do

    case Medium.get_voice(src_id, c_no, @default_voice_lang) do
      %Voice{} = v ->
        Vyasa.PubSub.publish(
          v,
          :voice_ack,
          sess_id
        )
        _ -> nil
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(msg, socket) do
    IO.inspect(msg, label: "unexpected message in @chapter")
    {:noreply, socket}
  end

  # NOTE: This is needed because a stream can't be reconfigured.
  # Consider the case where we move from :show_chapters -> :show_verses -> :show_chapters.
  # In this case, because the state is held @ the live_view side (DM), we will end up with a situation
  # where the stream (e.g. chapters stream) would have already been configed.
  # Hence, a maybe_stream_configure/3 is necessary to avoid throwing an error.
  defp maybe_stream_configure(
         %Socket{
           assigns: assigns
         } = socket,
         stream_name,
         opts
       )
       when is_list(opts) do
    case Map.has_key?(assigns, :streams) && Map.has_key?(assigns.streams, stream_name) do
      true ->
        socket

      false ->
        socket |> stream_configure(stream_name, opts)
    end
  end

  def maybe_config_stream(%Socket{} = socket, _, _) do
    socket
  end

  #Helper function for updating verse state across both stream and the k_v map

  defp mutate_verses(%Socket{} = socket, target_verse_id, mutated_verses) do
    socket
    |> stream_insert(
       :verses,
     mutated_verses[target_verse_id]
     )
    |> assign(:kv_verses, mutated_verses)
  end

  defp should_show_media_bridge(device_type, is_focusing?)
       when is_atom(device_type) and is_boolean(is_focusing?) do
    case {device_type, is_focusing?} do
      {:mobile, true} -> false
      {:mobile, false} -> true
      {_, _} -> true
    end
  end

  defp should_show_media_bridge(_, _) do
    true
  end
end
