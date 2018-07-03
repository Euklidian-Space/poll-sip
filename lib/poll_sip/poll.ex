defmodule PollSip.Poll do
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
    :: {:ok, %Poll{}}

  def award_votes(%Poll{candidates: candidates} = poll, name, votes) 
  when votes > 0 
  do 
    candidates = Enum.map(candidates, fn c -> 
      if c.name == name do
        %Candidate{c | vote_count: c.vote_count + votes}
      else
        c
      end
    end)

    { :ok, %Poll{poll | candidates: sort_by_votes(candidates)} }
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
end
