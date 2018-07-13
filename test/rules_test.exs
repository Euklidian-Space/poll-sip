defmodule RulesTest do 
  use ExUnit.Case, async: true
  alias PollSip.Rules

  describe "new/0" do 
    test "should return a Rules struct" do 
      assert %Rules{} = Rules.new 
    end 

    test "state should be :initialized" do 
      assert %Rules{state: :initialized} = Rules.new
    end 
  end 

  describe "check/2 :start" do 
    setup do 
      {:ok, fresh_state: Rules.new}
    end

    test "should change state to :polling_active",
    %{fresh_state: rules}
    do 
      assert %Rules{state: :polling_active}
        = Rules.check(rules, :start)
    end 
    
    test "should return :error if state was not :initialized" do 
      invalid_rules_state = %Rules{state: :wrong_state}
      assert :error 
        = Rules.check(invalid_rules_state, :start)
    end 
  end 

  describe "check/2 :end" do 
    setup do 
      {:ok, active_state: %Rules{state: :polling_active}}
    end 

    test "should change state to :polls_closed",
    %{active_state: rules}
    do 
      assert %Rules{state: :polls_closed} 
        = Rules.check(rules, :end)
    end 

    test "should return :error if state was not :polling_active" do 
      invalid_rules_state = %Rules{state: :wrong_state}
      assert :error 
        = Rules.check(invalid_rules_state, :end)
    end 
  end 

  describe "check/2 :award_votes" do 
    setup do 
      {:ok, active_state: %Rules{state: :polling_active}}
    end 

    test "should not change state",
    %{active_state: rules}
    do 
      assert %Rules{state: :polling_active}
        = Rules.check(rules, :award_votes)
    end 

    test "should return :error if state was not :polling_active" do 
      invalid_rules_state = %Rules{state: :wrong_state}
      assert :error 
        = Rules.check(invalid_rules_state, :award_votes)
    end 
  end 

  describe "check/2 :pause" do 
    setup do 
      {:ok, active_state: %Rules{state: :polling_active}}
    end 

    test "should change state to :polling_paused",
    %{active_state: rules}
    do 
      assert %Rules{state: :polling_paused} =
        Rules.check(rules, :pause)
    end 

    test "should return :error if state was not :polling_active" do 
      assert :error =
        Rules.check(%Rules{state: :wrong_state}, :pause)
    end 
  end 

  describe "check/2 :resume" do 
    setup do 
      {:ok, active_state: %Rules{state: :polling_paused}}
    end 

    test "should change state to :polling_active",
    %{active_state: rules} 
    do 
      assert %Rules{state: :polling_active} =
        Rules.check(rules, :resume)
    end 

    test "shoult return :error if state was not :polling_paused" do 
      assert :error =
        Rules.check(%Rules{state: :wrong_state}, :resume)
    end 
  end 
end 









