defmodule PollSip.TestHelpers do
  alias PollSip.Candidate

  def generateCandidates(1), do: generateCandidate()
  def generateCandidates(count) when count > 1 do
    Enum.reduce(1..count, [], fn _, candidates ->
      [generateCandidate() | candidates]
    end)
  end

  def randomize_vote_count(candidates) do 
    Enum.map(candidates, fn candidate -> 
      votes = Enum.random(1..50)
      {:ok, new_cand} = Candidate.cast_votes(candidate, votes)
      new_cand
    end)
  end 

  defp generateCandidate do
    meta_data = %{
      "address" => Faker.Address.street_address(),
      "id" => Faker.Code.isbn()
    }
    Candidate.new(Faker.String.base64(), meta_data)
    |> (fn {:ok, cand} -> cand end).()
  end
end
