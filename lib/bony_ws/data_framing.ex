defmodule BonyWs.DataFraming do
  import Bitwise, only: [bxor: 2]

  def new(opcode, data, opts) do
    %{
      opcode: nil,
      mask: opts[:mask] || false,
      payload: data
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

    %{
      opcode: op(opcode),
      mask: mask == 1,
      payload: mask(masking_key, payload),
      masked_paylaod: payload,
      masking_key: masking_key,
      rest: rest
    }
  end

  defp op(x) do
    case x do
      _ -> nil
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

  def encode() do
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
end
