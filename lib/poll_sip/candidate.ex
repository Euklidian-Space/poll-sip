defmodule PollSip.Candidate do
  @moduledoc false
  alias __MODULE__
  defstruct [:name, :meta_data, :vote_count]

  @spec new(String.t(), map()) 
    :: {:ok, %Candidate{}} | {:error, String.t()}
  
  def new(non_empty_string, meta_data \\ %{})
  def new(name, meta_data) when is_binary(name) do
    if String.length(name) < 8 do
      {:error, "candidate names must be atleast 8 characters"}
    else 
      {
        :ok,
        %Candidate{name: name, meta_data: meta_data, vote_count: 0}
      }
    end 
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
