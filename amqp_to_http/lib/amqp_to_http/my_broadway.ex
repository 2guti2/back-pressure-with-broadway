defmodule MyBroadway do
  use Broadway

  alias Broadway.Message

  @host Application.get_env(:amqp_to_http, :amqp_host)

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: MyBroadway,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
          queue: "telemetry",
          connection: [
            username: "guest",
            password: "guest",
            host: @host
          ],
          qos: [
            prefetch_count: 150
          ]},
        concurrency: 4
      ],
      processors: [
        default: [
          concurrency: 4
        ]
      ],
      batchers: [
        default: [
          batch_size: 2,
          batch_timeout: 15000,
          concurrency: 4
        ]
      ]
    )
  end

  def handle_message(_, message, _) do
    message
    |> Message.update_data(fn data -> Jason.decode!(data) end)
  end

  def handle_batch(_, messages, _, _) do
#    readings = messages |> group_readings_by_subscriptions()
#
#    readings
#    |> Enum.map(fn {id, data} ->
#      [data, Enum.find(@subscriptions, &(&1.id == id))]
#    end)
#    |> Enum.each(fn [data, subscription] -> send_readings_to_subscription(data, subscription) end)

    IO.inspect("batch")
    messages |> IO.inspect()
  end

#  defp group_readings_by_subscriptions(messages) do
#    messages
#    |> Enum.map(fn message -> message.data end)
#    |> Enum.reduce(%{}, fn message_data, readings ->
#      subscriptions_with_device(message_data["device_id"])
#      |> add_data_to_subscription_readings(readings, message_data)
#    end)
#  end
#
#  defp subscriptions_with_device(device_id) do
#    @subscriptions
#    |> Enum.filter(fn subscription ->
#      Enum.any?(subscription.devices, &(&1.id == device_id))
#    end)
#  end
#
#  defp add_data_to_subscription_readings(subscriptions, readings, message_data) do
#    Enum.reduce(subscriptions, readings, fn subscription, acc ->
#      Map.update(
#        readings,
#        subscription.id,
#        [message_data["data"]],
#        &[message_data["data"] | &1]
#      )
#    end)
#  end
#
#  defp send_readings_to_subscription(readings, %{endpoint: endpoint} = _subscription) do
#    HTTPoison.post(endpoint, Jason.encode!(%{readings: readings}), [
#      {"Content-Type", "application/json"}
#    ])
#  end
end
