defmodule PollSip.TestHelpers do
  alias PollSip.{Candidate, Poll, PollWorker, Rules}

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

  def sort_desc(candidates) do 
    Enum.sort_by(candidates, fn c -> c.vote_count end, &>=/2)
  end 

  def create_pollworker(name, candidates) do 
    poll = Poll.new(name, candidates)
    %PollWorker{poll: poll, rules: %Rules{}}
  end 

  def find_candidate(poll, candidate_name) do 
    Enum.find(poll.candidates, fn cand -> 
      cand.name == candidate_name 
    end)
  end 

  defp generateCandidate do
    meta_data = %{
      "address" => Faker.Address.street_address(),
      "id" => Faker.Code.isbn()
    }
    {:ok, cand} = Candidate.new(Faker.String.base64(), meta_data)

    cand
  end
end
