defmodule PollSip.Poll do
  @moduledoc false
  alias PollSip.{Poll, Candidate}
  @enforce_keys [:name, :candidates]
  defstruct [:name, :candidates]


  @spec new(String.t(), [%Candidate{}]) 
    :: {:ok, %Poll{}} | {:error, String.t()}

  def new(name, candidates) do
    case unique_names?(candidates) do
      true -> 
        {
          :ok,
          %Poll{name: name, candidates: sort_by_votes(candidates)}
        }

      _otherwise -> {:error, "candidate names must be unique"}
    end 
  end

  @spec award_votes(%Poll{}, String.t(), integer())
    :: {:ok, %Poll{}} | {:error, String.t()}

  def award_votes(%Poll{candidates: candidates} = poll, name, votes) 
  when votes > 0 
  do 
    case do_award_votes(candidates, name, votes) do 
      {:ok, candidates} -> 
        {:ok, %Poll{poll | candidates: sort_by_votes(candidates)}}

      {:name_not_found, candidate_name} ->
        {:error, "candidate name '#{candidate_name}' not found"}
    end 
  end 

  defp sort_by_votes(candidates) do 
    Enum.sort_by(candidates, fn c -> c.vote_count end, &>=/2)
  end 

  defp unique_names?(candidates) do 
    candidates
    |> Stream.map(fn c -> c.name end)
    |> Stream.uniq
    |> Enum.count
    |> (fn count -> count == Enum.count(candidates) end).()
  end 

  defp do_award_votes(candidates, candidate_name, votes, left \\ [])

  defp do_award_votes([], candidate, _votes, _),
  do: {:name_not_found, candidate}

  defp do_award_votes(
    [%Candidate{name: candidate} = cand | rest], 
    candidate,
    votes,
    left
  )
  do 
    right = [%Candidate{cand | vote_count: cand.vote_count + votes} | rest]
    {:ok, Enum.concat(left, right)}
  end

  defp do_award_votes([c | candidates], candidate, votes, left),
  do: do_award_votes(candidates, candidate, votes, [c | left])

end
