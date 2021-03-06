defmodule PollSip.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: PollSip.Worker.start_link(arg)
      # {PollSip.Worker, arg},
      {Registry, keys: :unique, name: Registry.PollWorker},
      PollSip.PollSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    :ets.new(:poll_workers, [:named_table, :public])
    opts = [strategy: :one_for_one, name: PollSip.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
