defmodule Vyasa.Medium.Playback do
  @moduledoc """
  The Playback struct is a medium-agnostic way of representing the playback of a generic "media".
  It shall be a reference struct which audio/video players shall use to sync up with each other.
  """
  alias Vyasa.Medium.{Playback, Meta}

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

  defimpl Jason.Encoder, for: Playback do
    def encode(
          %Playback{
            medium: medium,
            meta: meta,
            playing?: playing,
            played_at: played_at,
            paused_at: paused_at,
            elapsed: elapsed,
            current_time: current_time
          },
          opts
        ) do
      %{
        medium: medium,
        meta: meta,
        playing?: playing,
        played_at: played_at,
        paused_at: paused_at,
        elapsed: elapsed,
        current_time: current_time
      }
      |> Jason.Encode.map(opts)
    end
  end

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
