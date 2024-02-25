defmodule Vyasa.PubSub do
  @moduledoc """
    Publish Subscriber Pattern
  """
  alias Phoenix.PubSub

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

  def publish(message, event, topics) when is_list(topics) do
    topics |> Enum.map(fn topic -> publish(message, event, topic) end)
    message
  end

  def publish(%Vyasa.Medium.Voice{} = voice, event, sess_id) do
    PubSub.broadcast(__MODULE__, "media:session:#{sess_id}", {__MODULE__, event, voice})
    voice
  end

  def publish(message, event, topic) when not is_nil(topic) do
    PubSub.broadcast(Vyasa.PubSub, topic, {__MODULE__, event, message})
    message
  end

  def publish(message, _event, _topic) do
    message
  end

  def publish({:error, reason}, _event) do
    {:error, reason}
  end
end
