defmodule PollSip.PollSupervisor do 
  use Supervisor  
  alias PollSip.PollWorker

  #Public API

  def start_poll_worker(name: name, candidates: candidates), 
  do: Supervisor.start_child(__MODULE__, [[name: name, candidates: candidates]])

  def stop_poll_worker(name), 
  do: Supervisor.terminate_child(__MODULE__, pid_from_name(name))

  #Supervisor Callbacks 
  
  def start_link(_opts), 
  do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), 
  do: Supervisor.init([PollWorker], strategy: :simple_one_for_one)

  defp pid_from_name(name) do 
    PollWorker.via_tuple(name)
    |> GenServer.whereis
  end 
end 
