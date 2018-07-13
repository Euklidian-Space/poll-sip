defmodule PollTest do
  use ExUnit.Case, async: true
  alias PollSip.{Poll, TestHelpers, Candidate}

  setup do
    candidates = TestHelpers.generateCandidates(5)
    name = Faker.Lorem.sentence()
    {:ok, candidates: candidates, poll_name: name}
  end


  describe "new/2" do

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
      expected_order = Enum.sort_by(candidates, fn cand -> cand.vote_count end, &>=/2)
      {:ok, %Poll{candidates: received_candidates}} 
      = Poll.new(name, candidates)

      assert expected_order == received_candidates
    end 

    test "should ensure candidate names are unique",
    %{candidates: [candA, candB | rest], poll_name: poll_name}
    do
      candidates = 
        [%Candidate{candA | name: "john"}, %Candidate{candB | name: "john"} | rest] 
      expected_msg = "candidate names must be unique"

      assert {:error, ^expected_msg} 
        = Poll.new(poll_name, candidates)
    end 
  end

  describe "award_votes/3" do 
    setup %{candidates: cs, poll_name: n} do 
      {:ok, poll} = Poll.new(n, cs) 
      {:ok, poll: poll}
    end 

    test "should award votes to candidate of given name",
    %{poll: %Poll{candidates: [cand | _rest]} = poll}
    do 
      candidate_name = cand.name 
      expected_vote_count = cand.vote_count + 3

      assert {:ok, %Poll{candidates: received_candidates}} 
        = Poll.award_votes(poll, candidate_name, 3)
        
      received_candidate = Enum.find(received_candidates, fn c -> 
        c.name == candidate_name 
      end)

      assert received_candidate.vote_count == expected_vote_count
    end

    test "should keep candidates in descending order",
    %{poll: %Poll{candidates: [_, cand | _]} = poll}
    do 
      {:ok, %Poll{candidates: received_candidates}} 
        = Poll.award_votes(poll, cand.name, 3)
      
      expected_candidate_order = Enum.sort_by(received_candidates, fn c ->
        c.vote_count 
      end, &>=/2)

      assert received_candidates == expected_candidate_order
    end 

    test "should return {:error, 'candidate name john12345 not found'}",
    %{poll: poll} 
    do 
      name = "john12345"
      assert {:error, "candidate name 'john12345' not found"} = 
        Poll.award_votes(poll, name, 3)
    end 
  end 


end













