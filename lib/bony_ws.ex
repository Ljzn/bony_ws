defmodule BonyWs do
  @moduledoc """
  Documentation for `BonyWs`.
  """
  import Kernel, except: [send: 2]
  alias BonyWs.Handshake

  @doc """
  Open a connection to the websocket server, finish the handshake and return
  the client process.

  Current process will link to the client process, and receive the
  websocket messages.

  The message type is `{:ws_msg, {:done | :more, bytes} | :closed}`.

  Only support ipv4 addresses and domains without SSL.
  """
  @spec connect(String.t()) :: {:ok, pid}
  def connect(url) do
    uri = URI.parse(url)
    Handshake.start_link(uri)
  end

  @doc """
  Send msg to a websocket server.
  """
  def send_msg(pid, msg) do
    Process.send(pid, {:send_msg, msg}, [])
  end
end
