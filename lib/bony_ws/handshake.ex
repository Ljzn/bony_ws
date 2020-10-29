defmodule BonyWs.Handshake do
  @moduledoc """
  RFC6455 4. Opening Handshake
  """
  use GenServer

  @concat_string "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  def start_link(%URI{} = uri) do
    charlist_url = String.to_charlist(uri.host)

    ip =
      if is_ipv4(charlist_url) do
        charlist_url
      else
        get_ip(charlist_url)
      end

    GenServer.start_link(__MODULE__, %{ip: ip, charlist_url: charlist_url, uri: uri})
  end

  def init(%{ip: ip, uri: uri} = meta) do
    # FIXME: http only now, add https support
    {:ok, socket} = :gen_tcp.connect(ip, uri.port || 80, [:binary, {:active, true}], 5000)
    nonce = :crypto.strong_rand_bytes(16) |> Base.encode64()
    :ok = :gen_tcp.send(socket, upgrade_msg(uri, nonce))

    {:ok,
     Map.merge(
       meta,
       %{
         socket: socket,
         phase: :handshake,
         challenge: :crypto.hash(:sha, nonce <> @concat_string) |> Base.encode64()
       }
     )}
  end

  defp is_ipv4(addr) do
    match?(
      {:ok, _},
      addr
      |> :inet.parse_ipv4strict_address()
    )
  end

  defp get_ip(url) do
    {:ok, {:hostent, _, _, :inet, _, ips}} =
      url
      |> :inet_res.gethostbyname()

    hd(ips)
  end

  defp upgrade_msg(uri, nonce) do
    """
    GET / HTTP/1.1\r
    Host: #{uri.authority}\r
    Upgrade: websocket\r
    Connection: Upgrade\r
    Sec-WebSocket-Key: #{nonce}\r
    Sec-WebSocket-Version: 13\r\n
    """
  end

  def handle_info({:tcp, _port, data}, state) do
    {phase, msg} = handle_tcp(state.phase, data, state)
    respond_msg(state.socket, msg)
    {:noreply, %{state | phase: phase}}
  end

  def handle_info(msg, state) do
    IO.inspect(msg)
    {:noreply, state}
  end

  defp handle_tcp(:handshake, data, %{challenge: challenge}) do
    {:ok, {:http_response, _, 101, "Switching Protocols"}, rest} =
      :erlang.decode_packet(:http_bin, data, []) |> IO.inspect()

    case validate_headers(rest, fn
           {:Connection, up} ->
             String.downcase(up) == "upgrade"

           {:Upgrade, ws} ->
             String.downcase(ws) == "websocket"

           {"Sec-WebSocket-Accept", ch} ->
             ch == challenge

           _ ->
             true
         end) do
      :ok ->
        IO.inspect("goto data_framing")
        {:data_framing, ""}

      {:error, wrong_header} ->
        IO.inspect("falied because: #{inspect(wrong_header)}")
        {:failed, :close}
    end
  end

  defp validate_headers(data, fun) do
    Stream.cycle([1])
    |> Enum.reduce_while(data, fn _, data ->
      case :erlang.decode_packet(:httph_bin, data, []) do
        {:ok, {:http_header, _, key, _, value}, data} ->
          if fun.({key, value}) do
            {:cont, data}
          else
            {:halt, {:error, {key, value}}}
          end

        {:ok, :http_eoh, _} ->
          {:halt, :ok}
      end
    end)
  end

  defp respond_msg(socket, msg) do
    case msg do
      :close ->
        :gen_tcp.close(socket)

      msg ->
        :gen_tcp.send(socket, msg)
    end
  end
end