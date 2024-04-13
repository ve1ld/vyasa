  defmodule Vyasa.Medium.Meta do
    @moduledoc """
    Meta is a medium-agnostic struct for tracking metadata.
    """

    alias Vyasa.Medium.Meta

    defstruct [
      title: nil,
      artists: [],
      duration: 0, # time, in ms
      file_path: nil,
    ]

    defimpl Jason.Encoder, for: Meta do
      def encode(%Meta{ title: title, artists: artists, duration: duration, file_path: file_path }, opts) do
        %{ title: title, artists: artists, duration: duration, file_path: file_path }
        |> Jason.Encode.map(opts)
      end
    end



  end
