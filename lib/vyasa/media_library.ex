defmodule Vyasa.MediaLibrary do
  @moduledoc """
  Media Library is responsible for everything that relates to the content of what medium is played.

  Therefore, it's in charge of updating the Playback struct and loading the necessary media-related contexts.
  """
  alias Vyasa.Medium.{Voice}
  alias Vyasa.Medium

  defmodule Playback do
    @moduledoc """
    The Playback struct is the bridge between written and media player contexts.
    """


    defstruct [:medium, playing?: false, played_at: nil, paused_at: nil, elapsed: 0, current_time: 0]

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

  def gen_voice_playback(%Voice{} = voice) do
    Playback.new(%{
          medium: voice |>load_voice_events(),
          playing?: false,
    })
  end

  def load_voice_events(%Voice{} = voice) do
    voice
    |> Medium.get_voices!()
    |> List.first()
    |> Medium.Store.hydrate()
  end

 end
