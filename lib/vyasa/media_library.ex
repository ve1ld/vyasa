defmodule Vyasa.MediaLibrary do
  @moduledoc """
  The MediaLibrary context. For now, it shall mainly contain playback events.
  """

  defmodule Playback do
    @moduledoc """
    Manages the playback state
    """


    defstruct [:medium, playing?: false, played_at: nil, paused_at: nil, elapsed: 0]

    def new(%{} = attrs) do
      %Playback{
        medium: attrs.medium,
        playing?: attrs.playing?,
        played_at: nil,
        paused_at: nil,
        elapsed: 0,
      }
    end
  end
end
