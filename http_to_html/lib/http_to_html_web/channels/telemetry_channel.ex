defmodule HttpToHtmlWeb.TelemetryChannel do
  use HttpToHtmlWeb, :channel

  @impl true
  def join("telemetry:lobby", _payload, socket) do
    {:ok, socket}
  end

  def broadcast_all(event, payload)  do
    HttpToHtmlWeb.Endpoint.broadcast_from!(self(), "telemetry:lobby", event, payload)
  end
end
