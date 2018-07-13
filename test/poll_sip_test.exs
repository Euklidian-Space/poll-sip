defmodule PollSipTest do 
  use ExUnit.Case, async: true
  alias PollSip.{PollWorker}
  import PollSip.TestHelpers

  setup do 
    cand_map = Enum.reduce(1..5, %{}, fn _, m -> 
      [name, data] = generate_name_and_data()
      Map.put_new(m, name, data)
    end) 

    candidates = Enum.map(1..10, fn _ -> Faker.Name.name() end)

    name = Faker.String.base64()

    {:ok, cand_map: cand_map, poll_name: name, candidates: candidates}
  end 

  describe "create_poll/2" do 
    test "should start a poll worker process",
    %{cand_map: candidates, poll_name: name}
    do 
      assert :ok = PollSip.create_poll(name, candidates)   

      PollWorker.via_tuple(name)
      |> GenServer.whereis
      |> assert
    end 

    test "should return error tuple {:error, 'candidate names must be atleast 8 characters'}",
    %{poll_name: name}
    do
      cand_map = %{"invalid" => %{}}
      assert {:error, "candidate names must be atleast 8 characters"} = 
        PollSip.create_poll(name, cand_map)
    end 

    test "should return error tuple '{:error, 'poll name must be atleast 8 characters}'",
    %{cand_map: candidates}
    do 
      assert {:error, "poll name must be atleast 8 characters"} =
        PollSip.create_poll("name", candidates)
    end 

    test "should return :ok when a list of candidate names",
    %{candidates: candidates, poll_name: name}
    do 
      assert :ok = PollSip.create_poll(name, candidates)
    end 

    test "should return {:error, 'candidates must be a list of string or a map",
    %{poll_name: name}
    do 
      assert {:error, "candidates must be a list of strings or a map"} = 
        PollSip.create_poll(name, 1)
    end 
  end 

  describe "start_poll/1" do 
    setup %{cand_map: candidates, poll_name: name} do 
      :ok = PollSip.create_poll(name, candidates)
    end 

    test "should return :ok and start poll",
    %{poll_name: name}
    do 
      pid = name |> PollWorker.via_tuple |> GenServer.whereis
      assert :ok = PollSip.start_poll(name)   
      assert %PollWorker{rules: rules} =
        :sys.get_state(pid)

      assert rules.state == :polling_active
    end 

    test "should return {:error, 'poll name 'john12345' not found'}" do 
      assert {:error, "poll name 'john12345' not found"} = 
        PollSip.start_poll("john12345")
    end 
  end 

  describe "award_votes/3" do 
    setup %{candidates: candidates, poll_name: name} do 
      :ok = PollSip.create_poll(name, candidates)
      :ok = PollSip.start_poll(name)
    end 

    test "should return :ok",
    %{candidates: [candidate_name | _], poll_name: poll_name}
    do 
      assert :ok = PollSip.award_votes(poll_name, candidate_name, 1)
    end 
    
    test "should award votes to given candidate",
    %{candidates: [candidate_name | _], poll_name: poll_name}
    do 
      :ok = PollSip.award_votes(poll_name, candidate_name, 1)
      :ok = PollSip.award_votes(poll_name, candidate_name, 2)
      pid = poll_name |> PollWorker.via_tuple |> GenServer.whereis
      {:ok, cand} = PollWorker.find_candidate(pid, candidate_name)

      assert cand.vote_count == 3
    end 
    
    test "should return {:error, 'candidate name charles123 not found'}",
    %{poll_name: name}
    do 
      candidate = "charles123"
      assert {:error, "candidate name 'charles123' not found"} = 
        PollSip.award_votes(name, candidate, 5)
    end 

  end 

  describe "end_poll/1" do 
    setup %{candidates: candidates, poll_name: name} do 
      :ok = PollSip.create_poll(name, candidates)
      :ok = PollSip.start_poll(name)
    end 
    
    test "should return :ok",
    %{poll_name: name}
    do 
      assert :ok = PollSip.end_poll(name)
    end 

    test "should stop the poll worker process",
    %{poll_name: name}
    do 
      pid = PollWorker.via_tuple(name) |> GenServer.whereis
      :ok = PollSip.end_poll(name)
      refute Process.alive?(pid)
    end 

    test "should return {:error, 'poll name 'john' not found}" do 
      assert {:error, "poll name 'john' not found"} =
        PollSip.end_poll("john")
    end 
  end 
end 





