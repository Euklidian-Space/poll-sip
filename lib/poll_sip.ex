defmodule PollSip do
  @moduledoc """
  Documentation for PollSip.
  """
  alias PollSip.{PollSupervisor, Candidate, PollWorker}
  
  @doc """
  Starts a poll worker process with given name and candidates

  Returns ':ok' or '{:error, 'msg'}'.
  """
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
    case pid_from_name(name) do 
      nil -> {:error, "poll name '#{name}' not found"}

      pid -> PollWorker.start_poll(pid)
    end 
  end 

  def award_votes(poll_name, candidate_name, votes) do 
    case pid_from_name(poll_name) do 
      nil -> :error 

      pid -> PollWorker.award_votes(pid, candidate_name, votes)
    end 
  end 

  def end_poll(name) when is_binary(name) do 
    case pid_from_name(name) do 
      nil -> {:error, "poll name '#{name}' not found"}

      _ -> PollSupervisor.stop_poll_worker(name)
    end 
  end 

  defp create_candidates(candidates) when is_list(candidates),
  do: create_candidates_from_list(candidates)

  defp create_candidates(candidates) when is_map(candidates),
  do: create_candidates_from_map(candidates)

  defp create_candidates(_), 
  do: {:error, "candidates must be a list of strings or a map"}

  defp create_candidates_from_map(cand_map) do 
    Enum.reduce_while(cand_map, {:ok, []}, fn {cand_name, data}, {:ok, candidates} -> 
      case Candidate.new(cand_name, data) do 
        {:ok, cand} -> 
          {:cont, {:ok, [cand | candidates]}}

        err -> 
          {:halt, err}
      end 
    end)
  end 

  defp create_candidates_from_list(candidates) do 
    Enum.reduce_while(candidates, {:ok, []}, fn candidate, {:ok, cands} ->
      case Candidate.new(candidate) do 
        {:ok, cand} -> 
          {:cont, {:ok, [cand | cands]}}

        err ->
          {:halt, err}
      end 
    end)
  end 

  defp pid_from_name(name) do 
    PollWorker.via_tuple(name)
    |> GenServer.whereis
  end 
end
