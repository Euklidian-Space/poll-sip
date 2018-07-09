defmodule PollSupervisorTest do 
  use ExUnit.Case, async: true
  alias PollSip.{PollSupervisor, PollWorker, Poll, Rules, Candidate}
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
    test "should end a poll worker with given name",
    %{name: name, candidates: candidates}
    do 
      opts = [name: name, candidates: candidates]
      {:ok, child} = PollSupervisor.start_poll_worker(opts)
      assert :ok = PollSupervisor.stop_poll_worker(name)
      refute Process.alive?(child)
    end 
  end 
end 
