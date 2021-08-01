defmodule MqttToAmqp.TelemetrySubscriber do
  use Supervisor

  @broker_host Application.get_env(:mqtt_to_amqp, :mqtt_host)
  @broker_port 1883

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tortoise.Connection,
        [
          client_id: UUID.uuid1(),
          server: {Tortoise.Transport.Tcp, host: @broker_host, port: @broker_port},
          handler: {MqttToAmqp.TelemetryHandler, []},
          subscriptions: ["device/+/telemetry"]
        ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
