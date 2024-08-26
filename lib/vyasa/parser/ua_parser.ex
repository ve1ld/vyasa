defmodule Vyasa.UserAgentParser do
  @moduledoc """
  Uses the external library, ua_parser to add more fine-tuned judgement of
  what the current user-agent is.
  """
  def parse_user_agent(user_agent) do
    case UAParser.parse(user_agent) do
      %UAParser.UA{device: %UAParser.Device{family: "Smartphone"}} -> :mobile
      %UAParser.UA{device: %UAParser.Device{family: "Tablet"}} -> :tablet
      _ -> :desktop
    end
  end
end
