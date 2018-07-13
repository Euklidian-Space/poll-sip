defmodule PollSip do
  @moduledoc """
  Documentation for PollSip.
  """
  alias PollSip.{PollSupervisor, Candidate, PollWorker}
  
  def create_poll(string, map_or_list)

  def create_poll(name, candidates) do 
    with {:ok, candidates} <- create_candidates(candidates),
         {:ok, _} <- PollSupervisor.start_poll_worker(name: name, candidates: candidates) 
    do 
      :ok
    else
      err -> err 
    end 
  end 

  def start_poll(name) when is_binary(name) do 
    poll_exists?(name, fn pid -> PollWorker.start_poll(pid) end)
  end 

  def award_votes(poll_name, candidate_name, votes) do 
    poll_exists?(poll_name, fn pid -> 
      PollWorker.award_votes(pid, candidate_name, votes)
    end)
  end 

  def end_poll(name) when is_binary(name) do 
    poll_exists?(name, fn _ -> PollSupervisor.stop_poll_worker(name) end)
  end 

  def pause_polling(name) when is_binary(name) do 
    poll_exists?(name, fn pid -> PollWorker.pause_polling(pid) end)
  end 

  def resume_polling(name) when is_binary(name) do 
    poll_exists?(name, fn pid -> PollWorker.resume_polling(pid) end)
  end 

  defp create_candidates(candidates)
  when is_map(candidates) or is_list(candidates),
  do: create_candidates_from_data(candidates)

  defp create_candidates(_), 
  do: {:error, "candidates must be a list of strings or a map"}

  defp create_candidates_from_data(candidates_data) do 
    func = fn candidate, {:ok, candidates} ->
      case candidate do 
        {cand_name, data} -> Candidate.new(cand_name, data)
        _otherwise -> Candidate.new(candidate)
      end 
      |> case do 
        {:ok, cand} -> {:cont, {:ok, [cand | candidates]}}
        err -> {:halt, err}
      end 
    end

    Enum.reduce_while(candidates_data, {:ok, []}, func)
  end 

  defp poll_exists?(name, func) do 
    case pid_from_name(name) do 
      nil -> {:error, "poll name '#{name}' not found"}

      pid -> func.(pid)
    end 
  end 

  defp pid_from_name(name) do 
    PollWorker.via_tuple(name)
    |> GenServer.whereis
  end 
end
