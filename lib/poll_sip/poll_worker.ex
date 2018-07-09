defmodule PollSip.PollWorker do 
  use GenServer, start: {__MODULE__, :start_link, []}, restart: :transient
  alias PollSip.{PollWorker, Poll, Rules, Candidate}
  defstruct [:poll, :rules]

  ##Public API

  @spec start_poll(pid())
    :: :ok | {:error, String.t(), %Rules{}}
 
  def start_poll(poll_worker) when is_pid(poll_worker),
  do: GenServer.call(poll_worker, :start_poll)

  @spec end_poll(pid()) 
    :: {:ok, %PollWorker{}}

  def end_poll(poll_worker),
  do: GenServer.call(poll_worker, :end_poll)

  @spec award_votes(pid(), String.t(), integer())
    :: :ok | tuple()

  def award_votes(poll_worker, candidate_name, votes) when votes > 0,
  do: GenServer.call(poll_worker, {:vote, candidate_name, votes})

  def via_tuple(name) when is_binary(name),
  do: {:via, Registry, {Registry.PollWorker, name}}
  
  ##GenServer Callbacks
  
  def start_link(name: name, candidates: candidates) when is_binary(name),
  do: GenServer.start_link(__MODULE__, %{name: name, candidates: candidates}, name: via_tuple(name))

  def init(%{name: name, candidates: candidates}) do 
    case Poll.new(name, candidates) do 
      {:ok, poll} -> {:ok, %PollWorker{poll: poll, rules: %Rules{}}} 

      {:error, reason} -> {:stop, reason}
    end 
  end 

  def handle_call(
    :start_poll, 
    _from, 
    %PollWorker{rules: rules} = state_data
  ) 
  do 
    case chk_rules(rules, :start) do 
      {:error, _, _} = err ->
        reply_error(state_data, err)

      {:success, new_rules} ->
        new_state = %PollWorker{state_data | rules: new_rules}
        reply_success(new_state, :ok)
    end 
  end 

  def handle_call(
    :end_poll,
    _from,
    %PollWorker{rules: rules} = state_data
  )
  do 
    case chk_rules(rules, :end) do 
      {:error, _, _} = err ->
        reply_error(state_data, err)

      {:success, new_rules} -> 
        new_state = %PollWorker{state_data | rules: new_rules}
        reply_success(new_state, {:ok, new_state})
    end 
  end 

  def handle_call(
    {:vote, candidate_name, votes}, 
    _from,
    %PollWorker{rules: rules, poll: poll} = state_data
  ) 
  do 
    with {:success, new_rules} <- chk_rules(rules, :award_votes),
         {:ok, updated_poll} <- Poll.award_votes(poll, candidate_name, votes)
    do
      reply_success(%PollWorker{poll: updated_poll, rules: new_rules}, :ok)
    else
      err -> reply_error(state_data, err)
    end 
  end 

  ##Private helper functions
  defp reply_success(state_data, reply), 
  do: {:reply, reply, state_data}

  defp reply_error(state_data, err),
  do: {:reply, err, state_data} 

  defp chk_rules(rules, message) do 
    case Rules.check(rules, message) do 
      :error -> 
        {:error, "invalid rules state", rules}

      new_rules -> 
        {:success, new_rules}
    end 
  end

end 
