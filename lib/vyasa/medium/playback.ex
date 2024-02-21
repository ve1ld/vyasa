  defmodule Vyasa.Medium.Playback do
    @moduledoc """
    The Playback struct is the bridge between written and media player contexts.
    """

    defstruct [:medium, playing?: false, played_at: nil, paused_at: nil, elapsed: 0, current_time: 0]

    def new(%{} = attrs) do
      %Vyasa.Medium.Playback{
        medium: attrs.medium,
        playing?: attrs.playing?,
        played_at: nil, # timestamps
        paused_at: nil, # timestamps
        elapsed: 0, # seconds TODO: convert to ms to standardise w HTML players?
      }
    end
  end
