defmodule Vyasa.UserAgentParser do
  @moduledoc """
  Uses the UA Parser library to determine the device type from a user agent string.
  """

  def parse_user_agent(user_agent) when is_binary(user_agent) do
    ua = UAParser.parse(user_agent)

    cond do
      is_mobile?(ua) -> :mobile
      is_tablet?(ua) -> :tablet
      true -> :desktop
    end
  end

  def parse_user_agent(_), do: :unknown

  defp is_mobile?(ua) do
    ua.os.family in ["Android", "iOS", "Windows Phone"] or
      String.match?(ua.os.family, ~r/Mobile|iP(hone|od)|Android|BlackBerry|IEMobile|Silk/)
  end

  defp is_tablet?(ua) do
    (ua.os.family == "iOS" and ua.device.model == "iPad") or
      (ua.os.family == "Android" and not is_mobile?(ua))
  end
end
