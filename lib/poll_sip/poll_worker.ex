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

  @spec find_candidate(pid(), String.t())
    :: {:ok, %Candidate{}}

  def find_candidate(poll_worker, name) when is_pid(poll_worker) and is_binary(name),
  do: GenServer.call(poll_worker, {:find_candidate, name})

  def via_tuple(name) when is_binary(name),
  do: {:via, Registry, {Registry.PollWorker, name}}
  
  ##GenServer Callbacks
  
  def start_link(name: name, candidates: candidates) when is_binary(name),
  do: GenServer.start_link(__MODULE__, %{name: name, candidates: candidates}, name: via_tuple(name))

  def init(%{name: name, candidates: candidates}) do 
    send self(), {:set_state, name, candidates}
    fresh_state(name, candidates)
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
      new_state = %PollWorker{poll: updated_poll, rules: new_rules}
      :ets.insert(:poll_workers, {poll.name, new_state})
      reply_success(new_state, :ok)
    else
      err -> reply_error(state_data, err)
    end 
  end 

  def handle_call(
    {:find_candidate, name},
    _from,
    %PollWorker{poll: poll} = state_data
  )
  do
    func = fn cand -> cand.name == name end
    case Enum.find(poll.candidates, func) do 
      nil -> reply_error(state_data, {:name_not_found, name})

      cand -> reply_success(state_data, {:ok, cand})
    end 
  end 

  def handle_info({:set_state, name, candidates}, _state_data) do 
    with [] <- :ets.lookup(:poll_workers, name),
         {:ok, state_data} <- fresh_state(name, candidates)
    do 
      :ets.insert(:poll_workers, {name, state_data})
      {:noreply, state_data}
    else 
      [{^name, data}] ->
        {:noreply, data}

      {:stop, _} = stop_tuple -> 
        stop_tuple
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

  defp fresh_state(name, candidates) do 
    case Poll.new(name, candidates) do 
      {:ok, poll} -> {:ok, %PollWorker{poll: poll, rules: %Rules{}}} 

      {:error, reason} -> {:stop, reason}
    end 
  end 

end 
