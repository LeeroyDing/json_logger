defmodule Logger.Backends.JSON.TCPClient do
  use GenServer

  @reconnect_timeout 5000
  @tcp_options [:binary, {:packet, 0}, {:nodelay, true}, {:keepalive, true}]

  def start_link(host, port) do
    GenServer.start_link __MODULE__, {host, port}, []
  end

  def log_msg(client, msg) do
    GenServer.cast client, {:send_log, msg}
  end

  def stop(client) do
    GenServer.cast client, :stop
  end
  
  def init({host, port}) do
    {:ok, %{host: host, port: port, socket: nil, timeout: 0, stash: []}, 0}
  end

  def handle_cast({:send_log, msg}, %{socket: nil, timeout_start: timeout_start, stash: stash} = state) do
    stash = [msg | stash]
    {:noreply, %{state | stash: stash}, timeout_left(timeout_start)}
  end

  def handle_cast({:send_log, msg}, %{socket: socket, stash: stash} = state) do
    msg_list =
      (["", msg] ++ stash)
      |> Enum.reverse
      |> Enum.intersperse("\n")
    case :gen_tcp.send(socket, msg_list) do
      :ok ->
        {:noreply, state}
      {:error, _reason} ->
        # TODO: Error handling
        {:noreply, state}
    end
  end
  
  def handle_cast(:reconnect, %{host: host, port: port} = state) do
    case :gen_tcp.connect(host, port, @tcp_options) do
      {:ok, socket} ->
        {:noreply, %{state | socket: socket}}
      {:error, _} ->
        state = %{state | timeout_start: :os.system_time}
        {:noreply, state, @reconnect_timeout}
    end
  end

  def handle_cast(:stop, _state) do
    {:stop, :normal}
  end

  def handle_info(:timeout, %{socket: nil} = state) do
    GenServer.cast self(), :reconnect
    {:noreply, state}
  end
  
  def handle_info({:tcp_closed, socket}, %{socket: socket} = state) do
    {:noreply, %{state | socket: nil}, 0}
  end

  def terminate(_reason, %{socket: socket}) do
    :gen_tcp.close socket
    :ok
  end

  defp timeout_left(timeout_start) do
    case ((timeout_start + @reconnect_timeout) - :os.system_time) do
      n when n < 0 -> 0
      n -> n
    end
  end

end
