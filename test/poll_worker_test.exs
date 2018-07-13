defmodule PollWorkerTest do 
  use ExUnit.Case, async: true
  alias PollSip.{PollWorker, Poll, Rules, Candidate}
  import PollSip.TestHelpers

  setup do
    candidates = generateCandidates(5) |> randomize_vote_count
    name = Faker.Lorem.sentence()
    {:ok, pw} = PollWorker.start_link(name: name, candidates: candidates)

    on_exit fn -> 
      Process.exit(pw, :shutdown)
    end

    {:ok, candidates: candidates, poll_name: name, poll_worker: pw}
  end

  describe "start_link/2" do 
    test "should return {:ok, pid}", 
    %{candidates: candidates}
    do 
      assert {:ok, poll_worker} = PollWorker.start_link(name: "test_001", candidates: candidates)
      assert is_pid(poll_worker)
    end 

    test "should initialize state as a PollWorker struct",
    %{candidates: candidates}
    do 
      {:ok, poll_worker} = PollWorker.start_link(name: "test_002", candidates: candidates)
      assert %PollWorker{} = :sys.get_state(poll_worker)
    end 

    test "PollWorker struct should contain a Poll struct and Rules struct", 
    %{candidates: candidates}
    do 
      {:ok, poll_worker} = PollWorker.start_link(name: "test_003", candidates: candidates)

      assert %PollWorker{poll: %Poll{} = poll, rules: %Rules{} = rules}
        = :sys.get_state(poll_worker)

      %{candidates: received_candidates, name: received_poll_name} = poll
      %{state: rules_state} = rules

      expected_candidates = Enum.sort_by(candidates, fn c -> c.vote_count end, &>=/2)

      assert received_candidates == expected_candidates
      assert received_poll_name == "test_003"
      assert rules_state == :initialized
    end 

    test "should return {:error, 'reason'} if candidate names are not unique",
    %{candidates: [candA, candB | rest]}
    do 
       
      candidates = 
        [%Candidate{candA | name: "john"}, %Candidate{candB | name: "john"} | rest] 
      expected_msg = "candidate names must be unique"

      assert {:error, ^expected_msg} 
        = PollWorker.start_link(name: "test_004", candidates: candidates)
    end 

    test "should return {:error, 'poll name must be atleast 8 characters'}" do 
      expected_msg = "poll name must be atleast 8 characters"

      assert {:error, ^expected_msg} = 
        PollWorker.start_link(name: "fail", candidates: [])

      PollWorker.via_tuple("fail")
      |> GenServer.whereis 
      |> refute
    end 

    test "should start a named process",
    %{candidates: candidates}
    do 
      {:ok, _poll_worker} = PollWorker.start_link(name: "test_005", candidates: candidates)  
      PollWorker.via_tuple("test_005")
      |> GenServer.whereis 
      |> assert
    end 

    test "should update the :poll_workers ets table",
    %{candidates: candidates}
    do 
      name = "ets test"
      {:ok, pw} = 
        PollWorker.start_link(name: name, candidates: candidates)  

      %PollWorker{poll: expected_poll} = :sys.get_state(pw)
      expected_name = expected_poll.name

      assert [{^expected_name, %PollWorker{poll: received_poll}}] = 
        :ets.lookup(:poll_workers, name)

      assert expected_poll == received_poll
    end 

    test "should initialize state with state in ets table if it exists",
    %{candidates: candidates}
    do 
      name = "poll worker 1"
      modified_candidates = candidates 
        |> randomize_vote_count 
        |> sort_desc
      pw = create_pollworker(name, modified_candidates)
      :ets.insert(:poll_workers, {name, pw})

      {:ok, pid} = 
        PollWorker.start_link(name: name, candidates: candidates)

      assert pw == :sys.get_state(pid)
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

    test "should update ets table with new state",
    %{poll_worker: pw, candidates: [candidate | _], poll_name: poll_name}
    do 
      [{poll_name, poll_worker}] = :ets.lookup(:poll_workers, poll_name)

      %Candidate{vote_count: votes} 
        = find_candidate(poll_worker.poll, candidate.name)

      expected_vote_count = votes + 4

      :ok = PollWorker.award_votes(pw, candidate.name, 4)

      [{_, updated_poll_worker}] = :ets.lookup(:poll_workers, poll_name)

      assert %Candidate{vote_count: ^expected_vote_count}
        = find_candidate(updated_poll_worker.poll, candidate.name)
      
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

  describe "find_candidate/2" do 

    test "should find candidate by given name",
    %{candidates: [cand | _], poll_worker: pw}
    do 
      assert {:ok, ^cand} = PollWorker.find_candidate(pw, cand.name)      
    end 

    test "should return error tuple for name not found",
    %{poll_worker: pw}
    do 
      invalid_name = "some name not found"

      assert {:name_not_found, ^invalid_name} = 
        PollWorker.find_candidate(pw, invalid_name)
    end
  end 

  describe "pause_polling/1" do 
    setup %{poll_worker: pw} do 
      PollWorker.start_poll(pw)  
    end 

    test "should return :ok",
    %{poll_worker: pw} 
    do 
      assert :ok = PollWorker.pause_polling(pw)
    end 

    test "should pause poll taking",
    %{poll_worker: pw}
    do 
      :ok = PollWorker.pause_polling(pw)
      expected_rules_state = :polling_paused

      assert %PollWorker{rules: received_rules} = 
        :sys.get_state(pw)
      
      assert received_rules.state == expected_rules_state
    end 

    test "should return error tuple",
    %{poll_worker: pw}
    do 
      {:ok, _} = PollWorker.end_poll(pw)  

      assert {:error, "invalid rules state", %Rules{}} = 
        PollWorker.pause_polling(pw)
    end 
  end 

  describe "resume_polling/1" do 
    setup %{poll_worker: pw} do 
      PollWorker.start_poll(pw)
      PollWorker.pause_polling(pw)
    end 

    test "should return :ok",
    %{poll_worker: pw}
    do 
      assert :ok = PollWorker.resume_polling(pw)
    end 

    test "should resume polling",
    %{poll_worker: pw} 
    do 
      :ok = PollWorker.resume_polling(pw)

      assert %PollWorker{rules: received_rules} =
        :sys.get_state(pw)

      assert received_rules.state == :polling_active
    end 
  end 
  
  describe "requests while pollworker is paused" do 
    setup %{poll_worker: pw} do 
      PollWorker.start_poll(pw)
      PollWorker.pause_polling(pw)
    end 

    test "should return :poll_temp_closed",
    %{poll_worker: pw, candidates: [cand | _]} 
    do 
      assert :poll_temp_offline = 
        PollWorker.award_votes(pw, cand.name, 1)

      assert :poll_temp_offline =
        PollWorker.pause_polling(pw)

      assert :poll_temp_offline = 
        PollWorker.end_poll(pw)

      assert :poll_temp_offline =
        PollWorker.start_poll(pw)
    end 
  end 
end 




