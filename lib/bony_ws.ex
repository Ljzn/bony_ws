defmodule BonyWs do
  @moduledoc """
  Documentation for `BonyWs`.
  """
  import Kernel, except: [send: 2]
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

  @doc """
  Send msg to a websocket.
  """
  def send_msg(pid, msg) do
    Process.send(pid, {:send_msg, msg}, [])
  end
end
