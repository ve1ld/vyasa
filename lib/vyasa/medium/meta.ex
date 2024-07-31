defmodule Vyasa.Medium.Meta do
  @moduledoc """
  Meta is a medium-agnostic generic struct for tracking metadata for that medium doesn't entangle itself with DB meta.
   We can construct adapters to specifc metadata for specific mediums from here
   ## Adapters
   iex> from_voice(%Voice{meta: meta})

  Since this relates to rich media, the intent is also to contain information that is helpful for interfacing
  with APIs like the MediaSessions API (Browser).
  """

  alias Vyasa.Medium.Meta

  defstruct title: nil,
            artists: [],
            album: nil,
            artwork: %{},
            # time, in ms
            duration: 0,
            file_path: nil

  defimpl Jason.Encoder, for: Meta do
    def encode(
          %Meta{} = m,
          opts
        ) do
      Map.from_struct(m) |> Jason.Encode.map(opts)
    end
  end
end
