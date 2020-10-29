defmodule BonyWs.DataFraming do
  import Bitwise, only: [bxor: 2]

  def new(opcode, data, opts \\ []) do
    mask = opts[:mask] || true
    mask_key = opts[:mask_key] || :crypto.strong_rand_bytes(4)

    masked_payload =
      if mask do
        mask(mask_key, data)
      else
        nil
      end

    %{
      mask_key: mask_key,
      opcode: opcode,
      mask: mask,
      payload: data,
      masked_payload: masked_payload
    }
  end

  def decode(bin) do
    <<_fin::size(1), 0::size(3), opcode::integer-size(4), mask::size(1), rest::bitstring>> = bin
    {payload_length, rest} = payload_length(rest)

    {masking_key, rest} =
      case mask do
        1 ->
          <<mk::size(4)-bytes, rest::binary>> = rest
          {mk, rest}

        0 ->
          {"", rest}
      end

    <<payload::size(payload_length)-bytes, rest::bytes>> = rest
    mask = mask == 1

    %{
      opcode: deop(opcode),
      mask: mask,
      payload: if(mask, do: mask(masking_key, payload), else: payload),
      masked_paylaod: payload,
      masking_key: masking_key,
      rest: rest
    }
  end

  defp deop(x) do
    case x do
      0x1 ->
        :text

      0x2 ->
        :binary

      0x8 ->
        :close

      0x9 ->
        :ping

      0xA ->
        :pong
    end
  end

  defp enop(x) do
    case x do
      :text ->
        0x1

      :binary ->
        0x2

      :close ->
        0x8

      :ping ->
        0x9

      :pong ->
        0xA
    end
  end

  defp mask(key, data) do
    key = :erlang.binary_to_list(key)

    :erlang.binary_to_list(data)
    |> Enum.chunk_every(4)
    |> Enum.map(&do_mask(key, &1, key))
    |> IO.iodata_to_binary()
  end

  defp do_mask([hk | tk], [hd | data], key) do
    [bxor(hk, hd) | do_mask(tk, data, key)]
  end

  defp do_mask(_, [], _) do
    []
  end

  defp do_mask([], data, key) do
    do_mask(key, data, key)
  end

  def encode(%{opcode: op, mask: mask} = meta) do
    op = enop(op)
    payload = if mask, do: meta.masked_payload, else: meta.payload
    mask_key = if mask, do: meta.mask_key, else: <<>>
    mask = if mask, do: 1, else: 0

    <<1::size(1), 0::size(3), op::size(4), mask::size(1),
      encode_payload_length(byte_size(payload))::bitstring, mask_key::bytes, payload::bytes>>
  end

  defp payload_length(<<x::size(7), rest::binary>>) do
    case x do
      x when x < 126 ->
        {x, rest}

      126 ->
        <<len::size(16), rest::binary>> = rest
        {len, rest}

      127 ->
        <<len::size(64), rest::binary>> = rest
        {len, rest}
    end
  end

  defp encode_payload_length(x) do
    case x do
      x when x < 126 ->
        <<x::size(7)>>

      x when x <= 0xFFFF ->
        <<126::size(7), x::size(16)>>

      x ->
        <<127::size(7), x::size(64)>>
    end
  end
end
