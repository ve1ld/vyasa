defmodule Utils.Stream do
  @moduledoc """
  Contains functions useful for stream operations, that need not be
  web or server-specific.
  """
  alias Phoenix.LiveView.Socket
  import Phoenix.LiveView, only: [stream_configure: 3]

  def maybe_stream_configure(
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

  def maybe_stream_configure(%Socket{} = socket, _, _) do
    socket
  end
end
