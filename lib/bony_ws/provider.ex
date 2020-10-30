defmodule BonyWs.Provider do
  use GenServer
  require Logger

  def new() do
    %{
      ws_endpoint: nil,
      ws_pid: nil,
      requests: %{}
    }
  end

  def start_link(ws_url) do
    GenServer.start_link(__MODULE__, %{ws_endpoint: ws_url})
  end

  def send(server, method, params) do
    GenServer.call(server, {:send, method, params})
  end

  def init(%{ws_endpoint: url}) do
    {:ok, pid} = BonyWs.connect(url)

    {:ok, %{new() | ws_endpoint: url, ws_pid: pid}}
  end

  def handle_call({:send, method, params}, from, %{requests: requests, ws_pid: pid} = state) do
    id = System.unique_integer([:positive, :monotonic])
    json = json_rpc(method, params, id)
    send(pid, {:send_msg, json})
    requests = Map.put(requests, id, from)
    {:noreply, %{state | requests: requests}}
  end

  def handle_info({:ws_msg, msg}, %{requests: requests} = state) do
    %{"id" => id} = msg = Jason.decode!(msg)

    case requests do
      %{^id => from} ->
        GenServer.reply(from, msg)

      _ ->
        Logger.warn("Unexpected msg: #{msg}")
    end

    requests = Map.delete(requests, id)
    {:noreply, %{state | requests: requests}}
  end

  # Helpers
  defp json_rpc(method, params, id) do
    %{"jsonrpc" => "2.0", "method" => method, "params" => params, "id" => id}
    |> Jason.encode!()
  end
end
