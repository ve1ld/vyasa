defmodule Vyasa.Medium.Playback do
  @moduledoc """
  The Playback struct is a medium-agnostic way of representing the playback of a generic "media".
  It shall be a reference struct which audio/video players shall use to sync up with each other.
  """
  alias Vyasa.Medium.{Playback, Meta, Voice}

  @derive Jason.Encoder
  defstruct [
    :medium,
    meta: %Meta{},
    playing?: false,
    played_at: nil,
    paused_at: nil,
    # time unit: millseconds
    elapsed: 0,
    current_time: 0
  ]

  def new(%{} = attrs) do
    %Vyasa.Medium.Playback{
      playing?: attrs.playing?,
      meta: attrs.meta,
      # timestamps
      played_at: nil,
      # timestamps
      paused_at: nil,
      # seconds TODO: convert to ms to standardise w HTML players?
      elapsed: 0
    }
  end

  def create_playback(
        %Voice{
          events: _voice_events,
          title: title,
          file_path: file_path,
          duration: duration,
          meta:
            %{
              artists: artists,
              album: album,
              artwork: artwork
            } = _meta
        } = _voice,
        %{
          src: _src,
          type: _type,
          sizes: _sizes
        } = generated_artwork
      ) do
    init_playback(%Meta{
      title: title,
      artists: artists,
      album: album,
      artwork:
        case artwork do
          works when is_list(works) -> [generated_artwork | works]
          _ -> [generated_artwork]
        end,
      duration: duration,
      file_path: file_path
    })
  end

  def init_playback(
        %Meta{
          title: _title,
          artists: _artists,
          album: _album,
          artwork: _artwork,
          duration: _duration,
          file_path: _file_path
        } = meta
      ) do
    Playback.new(%{
      playing?: false,
      meta: meta
    })
  end

  def init_playback(nil) do
    init_playback()
  end

  def init_playback() do
    Playback.new(%{
      playing?: false,
      meta: nil
    })
  end
end
