defmodule BonyWs do
  @moduledoc """
  Documentation for `BonyWs`.
  """

  @doc """
  Open a connection to the websocket server, finish the handshake and return
  the socket.
  """
  @spec connect(String.t()) :: socket :: any
  def connect(url) do
    uri = URI.parse(url)
    BonyWs.Handshake.start_link(uri)
  end
end
