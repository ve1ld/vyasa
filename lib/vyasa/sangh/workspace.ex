defmodule Vyasa.Sangh.Workspace do
  use GenServer
  # a bit like a tuplespace per disciple
  # store curr_binding state

  def init(%{topic: topic, disciple: disciple}) do
    {:ok, %{topic: topic, disciple: disciple, last: %{}}}
  end


  def publish(pid, msg, event) do
    GenServer.cast(pid, {:publish, msg, event})
  end

  def last(pid, event) when is_pid(pid) do
    GenServer.call(pid, {:last, event})
  end

  def last(_, _event), do: nil


  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def handle_cast({:publish, msg, event}, %{last: last, topic: topic, disciple: %{name: name}} = state) do
    Vyasa.PubSub.publish({name, msg}, event, topic)
    {:noreply, %{state | last: last |> Map.put(event, msg)}}
  end

  def handle_call({:last, event}, __from, %{last: last} = state) do
    {:reply, Map.get(last, event, nil), state}
  end
end
