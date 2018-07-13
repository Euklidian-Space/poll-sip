defmodule CandidateTest do
  use ExUnit.Case, async: true
  alias PollSip.{Candidate}

  describe "new/2" do
    test "should return a new Candidate" do
      name = Faker.String.base64()
      meta_data = %{"id" => "1234_id", "length" => "2:03"}
      expected_vote_count = 0
      assert {
        :ok, 
        %Candidate{name: ^name, meta_data: ^meta_data, vote_count: received_vc}
      } = Candidate.new(name, meta_data)

      assert expected_vote_count == received_vc
    end

    test "second arg should default to empty map" do 
      name = Faker.String.base64()
      assert {
        :ok,
        %Candidate{meta_data: %{}, vote_count: 0}
      } = Candidate.new(name)
    end 

    test "should return {:error, 'candidate names cannot be blank'}" do 
      msg = "candidate names must be atleast 8 characters"
      assert {:error, ^msg}
        = Candidate.new("")
    end 
  end

  describe "cast_votes/2" do 
    setup do 
      name = Faker.String.base64()
      {:ok, candidate} = Candidate.new name 
      {:ok, candidate: candidate}
    end 

    test "should increase candidate votes", %{candidate: candidate} do 
      assert {
        :ok,
        %Candidate{vote_count: 2}
      } = Candidate.cast_votes(candidate, 2)
    end 
  end 

end
