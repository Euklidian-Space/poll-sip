defmodule PollSip.Rules do 
  @moduledoc false
  alias __MODULE__ 
  defstruct state: :initialized
  
  def new, do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :start), 
  do: %Rules{rules | state: :polling_active}

  def check(%Rules{state: :polling_active} = rules, :end), 
  do: %Rules{rules | state: :polls_closed}

  def check(%Rules{state: :polling_active} = rules, :pause), 
  do: %Rules{rules | state: :polling_paused}

  def check(%Rules{state: :polling_paused} = rules, :resume),
  do: %Rules{rules | state: :polling_active}
  
  def check(%Rules{state: :polling_active} = rules, :award_votes), 
  do: rules
  
  def check(_rules_state, _action), do: :error
end 
