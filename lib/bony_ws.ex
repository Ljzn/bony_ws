defmodule BonyWs do
  @moduledoc """
  Documentation for `BonyWs`.
  """
  alias BonyWs.{Handshake, DataFraming}

  @doc """
  Open a connection to the websocket server, finish the handshake and return
  the process.
  """
  @spec connect(String.t()) :: {:ok, pid}
  def connect(url) do
    uri = URI.parse(url)
    Handshake.start_link(uri)
  end

  def request(pid, msg) do
    data =
      DataFraming.new(:binary, msg)
      |> DataFraming.encode()

    send(pid, {:request, data})
  end
end
