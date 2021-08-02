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
          batch_size: 1000,
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
      update_subscriber_aux([], acc, message)
    end)
  end

  defp update_subscriber_aux([], [], subscriber), do: [subscriber]
  defp update_subscriber_aux(acc, [], subscriber), do: acc
  defp update_subscriber_aux(acc, [h], subscriber) do
    if h.subscriber == subscriber.subscriber do
      updated_sub = h |> Map.put(:payload, h.payload ++ subscriber.payload)
      update_subscriber_aux(acc ++ [updated_sub], [], subscriber)
    else
      update_subscriber_aux(acc ++ [h, subscriber], [], subscriber)
    end
  end
  defp update_subscriber_aux(acc, [h | t], subscriber) do
    if h.subscriber == subscriber.subscriber do
      updated_sub = h |> Map.put(:payload, h.payload ++ subscriber.payload)
      update_subscriber_aux(acc ++ [updated_sub], t, subscriber)
    else
      update_subscriber_aux(acc ++ [h], t, subscriber)
    end
  end

  defp get_id(id) do
    {int, _} = Integer.parse(id)
    if int <= 100 do
      100
    else
      if int <= 200 do
        200
      else
        if int <= 300 do
          300
        else
          400
        end
      end
    end
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
