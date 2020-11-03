# BonyWs

A light weight websocket client. You can handle data frame by frame.

Example:

```ex
iex> {:ok, pid} = BonyWs.connect "ws://echo.websocket.org"
{:ok, #PID<0.228.0>}
iex> BonyWs.send_msg pid, "hello"
:ok  
iex> flush
{:ws_msg, {:done, "hello"}}
:ok
```

## Limitations

Only support ipv4 addresses and domains without SSL now.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bony_ws` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bony_ws, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bony_ws](https://hexdocs.pm/bony_ws).

