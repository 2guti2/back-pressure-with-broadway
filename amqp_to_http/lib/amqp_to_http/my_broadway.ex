defmodule MyBroadway do
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo

  @amqp_host Application.get_env(:amqp_to_http, :amqp_host)
  @http_host Application.get_env(:amqp_to_http, :http_host)
  @endpoint "http://#{@http_host}:4000/api/v1/telemetry"
  @headers [{"Content-Type", "application/json"}]

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
          batch_size: 100,
          batch_timeout: 5000,
          concurrency: 4
        ]
      ]
    )
  end

  def handle_message(_, message, _) do
    message
    |> Message.update_data(fn data -> Jason.decode!(data) end)
    |> (fn (msg) -> Message.put_batch_key(msg, get_subscriber_id(msg.data["client_id"])) end).()
  end

  def handle_batch(_, messages, %BatchInfo{batch_key: subscriber_id}, _) do
    batch = %{
      telemetry: %{
        subscriber: subscriber_id,
        payload: messages |> Enum.map(
          fn message ->
            message.data["payload"]
          end
        )
      }
    }

    HTTPoison.post(@endpoint, Jason.encode!(batch), @headers)

    messages
  end

  defp get_subscriber_id(client_id) do
    first_char = String.at(client_id, 0)
    {int, _} = Integer.parse(first_char)
    int
  end
end
