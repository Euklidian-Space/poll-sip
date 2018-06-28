defmodule PollSip.Poll do
  alias PollSip.{Poll, Candidate}
  @enforce_keys [:name, :candidates]
  defstruct [:name, :candidates]

  @spec new(String.t(), [%Candidate{}]) :: {:ok, %Poll{}}
  def new(name, candidates) do
    {
      :ok,
      %Poll{name: name, candidates: sort_by_votes(candidates)}
    }
  end

  defp sort_by_votes(candidates) do 
    Enum.sort_by(candidates, fn c -> c.vote_count end)
  end 
end
