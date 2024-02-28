  defmodule Vyasa.Medium.Playback do
    @moduledoc """
    The Playback struct is a medium-agnostic way of representing the playback of a generic "media".
    It shall be a reference struct which audio/video players shall use to sync up with each other.
    """
    alias Vyasa.Medium.{Playback}

    defstruct [:medium, playing?: false, played_at: nil, paused_at: nil, elapsed: 0, current_time: 0]

    def new(%{} = attrs) do
      %Vyasa.Medium.Playback{
        playing?: attrs.playing?,
        played_at: nil, # timestamps
        paused_at: nil, # timestamps
        elapsed: 0, # seconds TODO: convert to ms to standardise w HTML players?
      }
    end

    def init_playback() do
      Playback.new(%{
            playing?: false
      })
    end
end
