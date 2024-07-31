defmodule Vyasa.Medium.Meta do
  @moduledoc """
  Meta is a medium-agnostic struct for tracking metadata for that medium.

  Since this relates to rich media, the intent is also to contain information that is helpful for interfacing
  with APIs like the MediaSessions API.
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
          %Meta{
            title: title,
            artists: artists,
            album: album,
            artwork: artwork,
            duration: duration,
            file_path: file_path
          },
          opts
        ) do
      %{
        title: title,
        artists: artists,
        album: album,
        artwork: artwork,
        duration: duration,
        file_path: file_path
      }
      |> Jason.Encode.map(opts)
    end
  end
end
