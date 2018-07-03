defmodule PollWorkerTest do 
  use ExUnit.Case, async: true
  alias PollSip.{PollWorker, Poll, Rules, Candidate}
  import PollSip.TestHelpers

  setup do
    candidates = generateCandidates(5) |> randomize_vote_count
    name = Faker.Lorem.sentence()
    {:ok, pw} = PollWorker.start_link(name, candidates)
    {:ok, candidates: candidates, poll_name: name, poll_worker: pw}
  end

  describe "start_link/2" do 
    test "should return {:ok, pid}", 
    %{candidates: candidates, poll_name: name}
    do 
      assert {:ok, poll_worker} = PollWorker.start_link(name, candidates)
      assert is_pid(poll_worker)
    end 

    test "should initialize state as a PollWorker struct",
    %{candidates: candidates, poll_name: name}
    do 
      {:ok, poll_worker} = PollWorker.start_link(name, candidates)
      assert %PollWorker{} = :sys.get_state(poll_worker)
    end 

    test "PollWorker struct should contain a Poll struct and Rules struct", 
    %{candidates: candidates, poll_name: name}
    do 
      {:ok, poll_worker} = PollWorker.start_link(name, candidates)

      assert %PollWorker{poll: %Poll{} = poll, rules: %Rules{} = rules}
        = :sys.get_state(poll_worker)

      %{candidates: received_candidates, name: received_poll_name} = poll
      %{state: rules_state} = rules

      expected_candidates = Enum.sort_by(candidates, fn c -> c.vote_count end, &>=/2)

      assert received_candidates == expected_candidates
      assert received_poll_name == name 
      assert rules_state == :initialized
    end 

    test "should return {:error, 'reason'} if candidate names are not unique",
    %{candidates: [candA, candB | rest], poll_name: name}
    do 
       
      candidates = 
        [%Candidate{candA | name: "john"}, %Candidate{candB | name: "john"} | rest] 
      expected_msg = "candidate names must be unique"

      assert {:error, ^expected_msg} 
        = PollWorker.start_link(name, candidates)
    end 

    test "should start a named process",
    %{candidates: candidates, poll_name: name}
    do 
      {:ok, poll_worker} = PollWorker.start_link(name, candidates)  
      PollWorker.via_tuple(name)
      |> GenServer.whereis 
      |> assert
    end 
  end 

  describe "start_poll/1" do 
    test "should return :ok and update rules state",
    %{poll_worker: pw}
    do 
      :ok = PollWorker.start_poll(pw)

      assert %PollWorker{rules: rules} = :sys.get_state(pw)
      assert rules.state == :polling_active
    end 

    test "should return {:error, 'invalid rules state'} if rules state was not :initialized",
    %{poll_worker: pw}
    do 
      :ok = PollWorker.start_poll(pw) 

      assert {:error, "invalid rules state", %Rules{}}
        = PollWorker.start_poll(pw)
    end 
  end 

  describe "end_poll/1" do 
    test "should return {:ok, state} and update rules state",
    %{poll_worker: pw}
    do 
      :ok = PollWorker.start_poll(pw)

      assert {:ok, %PollWorker{rules: rules}} 
        = PollWorker.end_poll(pw)
    
      assert rules.state == :polls_closed
    end 

    test "should return {:error 'invalid rules state'} if rules state was not :polling_active",
    %{poll_worker: pw}
    do 
      assert {:error, "invalid rules state", %Rules{}}
        = PollWorker.end_poll(pw)
    end 
  end 

  describe "award_votes/3" do 
    setup %{poll_worker: pw} do 
      PollWorker.start_poll(pw)  
    end 
    
    test "should return :ok and award votes to given candidate name",
    %{poll_worker: pw, candidates: [candidate | _]}
    do 
      assert :ok = PollWorker.award_votes(pw, candidate.name, 4) 

      %PollWorker{poll: %Poll{candidates: received_candidates}} 
        = :sys.get_state(pw)
      
      received_candidate = Enum.find(received_candidates, fn c -> 
        c.name == candidate.name 
      end)

      expected_vote_count = 4 + candidate.vote_count

      assert received_candidate.vote_count 
        == expected_vote_count
    end 
    
    test "should return error tuple",
    %{poll_worker: pw}
    do 
      PollWorker.end_poll(pw)

      assert {:error, "invalid rules state", %Rules{}}
        = PollWorker.award_votes(pw, "some name", 4)
    end 
  end 

  describe "via_tuple/0" do 
    test "should return {:via, Registry, {Registry.PollWorker, 'name'}",
    %{poll_name: name}
    do 
      assert {:via, Registry, {Registry.PollWorker, ^name}}
        = PollWorker.via_tuple(name)
    end 
  end 

end 




