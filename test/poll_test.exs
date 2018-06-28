defmodule PollTest do
  use ExUnit.Case, async: true
  alias PollSip.{Poll, TestHelpers}

  describe "new/2" do
    setup do
      candidates = TestHelpers.generateCandidates(5)
      name = Faker.Lorem.sentence()
      {:ok, candidates: candidates, poll_name: name}
    end

    test "should return a new Poll", 
    %{candidates: candidates, poll_name: name} 
    do
      assert {:ok, %Poll{candidates: received_candidates}}
        = Poll.new(name, candidates)

      assert received_candidates == candidates
    end

    test "should ensure candidates are ordered by votes", 
    %{candidates: candidates, poll_name: name} 
    do 
      candidates = TestHelpers.randomize_vote_count(candidates)
      expected_order = Enum.sort_by(candidates, fn cand -> cand.vote_count end)
      {:ok, %Poll{candidates: received_candidates}} 
      = Poll.new(name, candidates)

      assert expected_order == received_candidates
    end 
  end
end
