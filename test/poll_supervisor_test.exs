defmodule PollSupervisorTest do 
  use ExUnit.Case, async: true
  alias PollSip.{PollSupervisor, PollWorker}
  import PollSip.TestHelpers

  setup do 
    candidates = generateCandidates(5) |> randomize_vote_count
    name = Faker.Lorem.sentence()
    {:ok, name: name, candidates: candidates}
  end 

  test "PollSupervisor should be available on startup" do 
    assert GenServer.whereis(PollSupervisor)
  end 

  describe "start_poll_worker/1" do 
    test "should start a poll worker with given name and candidates",
    %{name: name, candidates: candidates}
    do 
      opts = [name: name, candidates: candidates]
      assert {:ok, child} = PollSupervisor.start_poll_worker(opts)
      assert %PollWorker{poll: p} = :sys.get_state(child)

      assert p.name == name 
      assert p.candidates == sort_desc(candidates)
    end 
  end 

  describe "stop_poll_worker/1" do 
    setup %{name: name, candidates: candidates} do 
      {:ok, poll_worker} 
        = PollSupervisor.start_poll_worker(name: name, candidates: candidates)
      {:ok, poll_worker: poll_worker}
    end 

    test "should end a poll worker with given name",
    %{name: name, poll_worker: pw}
    do 
      assert :ok = PollSupervisor.stop_poll_worker(name)
      refute Process.alive?(pw)
    end 

    test "should delete entry in poll_workers ets table",
    %{name: name}
    do 
      :ok = PollSupervisor.stop_poll_worker(name)
      assert [] = :ets.lookup(:poll_workers, name)
    end 
  end 
end 












