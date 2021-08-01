defmodule MqttToAmqp.TelemetrySender do
  use GenServer

  @host Application.get_env(:mqtt_to_amqp, :amqp_host)
  @exchange    "telemetry_exchange"
  @queue       "telemetry"
  @queue_error "#{@queue}_error"

  defmodule Message do
    @derive Jason.Encoder
    defstruct [:client_id, :payload, :request_id]
  end

  # Client

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default, name: __MODULE__)
  end

  def send(client_id, payload) do
    GenServer.cast(__MODULE__, {:queue_telemetry, client_id, payload})
  end

  # Server (callbacks)

  @impl true
  def init(_opts) do
    {:ok, connection} = AMQP.Connection.open("amqp://guest:guest@#{@host}")
    {:ok, channel} = AMQP.Channel.open(connection)

    state = %{connection: connection, channel: channel}
    {:ok, state, {:continue, :create_queue}}
  end

  @impl true
  def handle_continue(:create_queue, %{channel: channel} = state) do
    {:ok, _} = AMQP.Queue.declare(channel, @queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} = AMQP.Queue.declare(channel, @queue,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", :longstr, ""},
        {"x-dead-letter-routing-key", :longstr, @queue_error}
      ]
    )
    :ok = AMQP.Queue.bind(channel, @queue, @exchange)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:queue_telemetry, client_id, payload}, %{channel: channel} = state) do
     Task.start(fn ->
       queue_message(channel, client_id, payload)
     end)

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{connection: connection}) do
    AMQP.Connection.close(connection)
  end

  defp queue_message(channel, client_id, payload) do
    request_id =
      :erlang.unique_integer()
      |> :erlang.integer_to_binary()
      |> Base.encode64()

    message = %Message{
      client_id: client_id,
      payload: Jason.decode!(payload),
      request_id: request_id
    }

    :ok = AMQP.Basic.publish(channel, "", @queue, Jason.encode!(message))
  end
end
