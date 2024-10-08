defmodule Vyasa.PubSub do
  @moduledoc """
    Publish Subscriber Pattern
  """
  alias Phoenix.PubSub
  alias Vyasa.Medium.{Voice}

  def subscribe(topic, opts \\ []) do
    PubSub.subscribe(Vyasa.PubSub, topic, opts)
  end

  def unsubscribe(topic) do
    PubSub.unsubscribe(Vyasa.PubSub, topic)
  end

  def publish({:ok, message}, event, topics) when is_list(topics) do
    topics
    |> Enum.map(fn topic -> publish(message, event, topic) end)

    {:ok, message}
  end

  def publish({:ok, message}, event, topic) do
    PubSub.broadcast(Vyasa.PubSub, topic, {__MODULE__, event, message})
    {:ok, message}
  end

  @doc """
  Publishes %Voice{} structs, any duplicate message check shall be done implicitly, based on the
  struct that is being passed.
  """
  def publish(%Voice{} = voice, event, sess_id) do
    msg = {__MODULE__, event, voice}
    PubSub.broadcast(__MODULE__, "media:session:#{sess_id}", msg)
    voice
  end

  def publish(message, event, topics) when is_list(topics) do
    topics |> Enum.map(fn topic -> publish(message, event, topic) end)
    message
  end

  def publish(message, event, topic) when not is_nil(topic) do
    msg = {__MODULE__, event, message}
    PubSub.broadcast(Vyasa.PubSub, topic, msg)
    message
  end

  def publish(message, _event, _topic) do
    message
  end

  def publish({:error, reason}, _event) do
    {:error, reason}
  end
end
