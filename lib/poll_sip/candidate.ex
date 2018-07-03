defmodule PollSip.Candidate do
  alias __MODULE__
  defstruct [:name, :meta_data, :vote_count]

  @spec new(String.t(), map()) :: {:ok, %Candidate{}}
  def new(name, meta_data \\ %{}) when is_binary(name) do
    {
      :ok,
      %Candidate{name: name, meta_data: meta_data, vote_count: 0}
    }
  end

  @spec cast_votes(%Candidate{}, integer()) :: {:ok, %Candidate{}}
  def cast_votes(%Candidate{vote_count: count} = candidate, votes)
  when votes > 0 
  do 
    { 
      :ok,
      %Candidate{candidate | vote_count: count + votes}
    }
  end
end
