defmodule Logger.Error.JSON do
  require Logger

  use GenEvent

  def init(_mod, []) do
    {:ok, []}
  end

  def handle_call({:configure, new_keys}, _state), do: {:ok, :ok, new_keys}

  def handle_event({kind, _, _} = msg, state) when kind in [:error, :error_report] do
    msg
    |> inspect(pretty: true)
    |> String.replace("\n", "\\\\n")
    |> Logger.error
    {:ok, state}
  end

  def handle_event(_msg, state) do
    {:ok, state}
  end
end
