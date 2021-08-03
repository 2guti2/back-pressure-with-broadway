defmodule MqttFlooder do
  @moduledoc false

  @clients 10
  @msg_per_client 1000

  def flood do
    {:ok, pid} = Agent.start_link(fn -> 0 end)
    count = fn -> Agent.get_and_update(pid, fn i -> {i, i + 1} end) end

    for i <- 1..@clients do
      spawn(fn ->
        client_id = UUID.uuid4()
        Tortoise.Supervisor.start_child(
          client_id: client_id,
          handler: {Tortoise.Handler.Logger, []},
          server: {Tortoise.Transport.Tcp, host: 'localhost', port: 1883}
        )
        for j <- 1..@msg_per_client do
          count = count.()
          IO.inspect("Message published #{count}")
          Tortoise.publish(client_id, "device/#{count}/telemetry", "{\"msgnum\": \"#{count}\"}", qos: 0)
        end
      end)
    end
  end
end
