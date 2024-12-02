defmodule Vyasa.Sangh.Assembly do
  use DynamicSupervisor
  alias Vyasa.Sangh.Workspace

  @moduledoc """
  Dynamic Supervisor for all sangh realtime behaviour, registry managed by parent Partition Supervisor

  Gate -> Tracks Presence related information

  PubSub -> Handles sangh based topic communication from many to many

  Workspace -> Workspace tuplespace-like handles all state cache per disciple sharing relevant session state.

  """

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def join(pid, session, disciple) do
    listen(session)
    spec = %{id: Workspace, start: {Workspace, :start_link, [%{topic: topic(session), disciple: disciple}]}}

    {:ok, works_id} = DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {__MODULE__, self()}},
      spec)

    Vyasa.Gate.track(pid, topic(session), %{disciple | node: works_id})

    {:ok, works_id}
  end


  def leave(pid, session, disciple) do
    Vyasa.PubSub.unsubscribe(topic(session))
    Vyasa.Gate.exit(pid, topic(session), disciple)
  end


  ## helper fns

  def orate(binding, %{works: wid})do
    Workspace.publish(wid, {__MODULE__, binding}, :bind)
  end

  def whois(username, session) do
    Vyasa.Gate.get_by_key(topic(session), username)
  end

  ## referents to disciples
  def id_disciples(session) do
    Vyasa.Gate.list_users(topic(session))
    |> Enum.into(%{}, fn %{id: id} = dis -> {id, dis} end)

  end

  def listen(session) do
    Vyasa.PubSub.subscribe(topic(session))
  end

  defp topic(session) do
    "sangh::" <> session
  end

end
