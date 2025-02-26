defmodule VyasaWeb.Utils.Stream do
  @moduledoc """
  Contains functions useful for stream operations, that need not be
  web or server-specific.
  """
  alias Phoenix.LiveView.Socket
  import Phoenix.LiveView, only: [stream_configure: 3]

  @doc """
  Configures a stream using the provided opts, if that stream is not configured yet.

  WARNING: this does not RECONFIGURE (i.e. update the config of the stream), its simply configures it
  if the stream isn't configured yet.

  NOTE: This is needed because a stream can't be reconfigured.
  Consider the case where we move from :show_chapters -> :show_verses -> :show_chapters.
  In this case, because the state is held @ the live_view side (DM), we will end up with a situation
  where the stream (e.g. chapters stream) would have already been configed.
  Hence, a maybe_stream_configure/3 is necessary to avoid throwing an error.
  """
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
