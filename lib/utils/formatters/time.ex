defmodule Utils.Formatters.Time do
  alias Utils.Formatters.TimeDisplay

  @doc """
  Formats the given DateTime into a human-friendly string.

  ## Examples

      iex> datetime = DateTime.utc_now()
      iex> Utils.Formatters.Time.human_friendly_time(datetime)
      %Utils.Formatters.TimeDisplay{formatted_time: "just now", original_datetime: datetime}
  """
  def human_friendly_time(datetime) when is_struct(datetime, DateTime) do
    now = DateTime.utc_now()

    # Calculate the difference in seconds
    seconds_diff = DateTime.diff(now, datetime)

    formatted_time =
      cond do
        seconds_diff < 60 -> "just now"
        seconds_diff < 3600 -> "#{div(seconds_diff, 60)} minutes ago"
        seconds_diff < 86400 -> "#{div(seconds_diff, 3600)} hours ago"
        true -> "#{div(seconds_diff, 86400)} days ago"
      end

    %TimeDisplay{formatted_time: formatted_time, original_datetime: datetime}
  end
end
