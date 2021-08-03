defmodule MyBroadway do
  use Broadway

  alias Broadway.Message

  @amqp_host Application.get_env(:amqp_to_http, :amqp_host)
  @http_host Application.get_env(:amqp_to_http, :http_host)
  @endpoint "http://#{@http_host}:4000/api/v1/telemetry"

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
            host: @amqp_host
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
          batch_size: 400,
          batch_timeout: 15000,
          concurrency: 4
        ]
      ]
    )
  end

  def handle_message(_, message, _) do
    IO.inspect("New reading")
    IO.inspect(message.data)
    message
    |> Message.update_data(fn data -> Jason.decode!(data) end)
  end

  def handle_batch(_, messages, _, _) do
    IO.inspect("New batch")
    Enum.map(messages, fn message ->
     %{
       subscriber: get_id(message.data["client_id"]),
       payload: [message.data["payload"]]
     }
    end)
    |> merge_payload_by_subscriber()
    |> IO.inspect()
    |> send_readings_to_subscription(@endpoint)

    messages
  end

  def merge_payload_by_subscriber(messages) do
    Enum.reduce(messages, [], fn message, acc ->
      update_subscriber_aux([], acc, message, false)
    end)
  end

  defp update_subscriber_aux([], [], subscriber, _), do: [subscriber]
  defp update_subscriber_aux(acc, [], subscriber, false), do: acc ++ [subscriber]
  defp update_subscriber_aux(acc, [], _subscriber, true), do: acc
  defp update_subscriber_aux(acc, lst, _subscriber, true), do: acc ++ lst
  defp update_subscriber_aux(acc, [h], subscriber, false) do
    if h.subscriber == subscriber.subscriber do
      updated_sub = h |> Map.put(:payload, h.payload ++ subscriber.payload)
      update_subscriber_aux(acc ++ [updated_sub], [], subscriber, true)
    else
      update_subscriber_aux(acc ++ [h], [], subscriber, false)
    end
  end
  defp update_subscriber_aux(acc, [h | t], subscriber, false) do
    if h.subscriber == subscriber.subscriber do
      updated_sub = h |> Map.put(:payload, h.payload ++ subscriber.payload)
      update_subscriber_aux(acc ++ [updated_sub], t, subscriber, true)
    else
      update_subscriber_aux(acc ++ [h], t, subscriber, false)
    end
  end

#  defp get_id(id) do
#    {int, _} = Integer.parse(id)
#
#    case int do
#      x when x <= 10 -> 10
#      x when x <= 20 -> 20
#      x when x <= 30 -> 30
#      x when x <= 40 -> 40
#      x when x <= 50 -> 50
#      _ -> 100
#    end
#  end

  defp get_id(id) do
    first_char = String.at(id, 0)
    {int, _} = Integer.parse(first_char)
    int
  end

  defp send_readings_to_subscription(readings, endpoint) do
    for reading <- readings do
      json = Jason.encode!(%{ telemetry: reading })
      HTTPoison.post(endpoint, json, [
        {"Content-Type", "application/json"}
      ])
    end
  end
end
