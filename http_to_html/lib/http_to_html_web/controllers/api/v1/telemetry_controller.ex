defmodule HttpToHtmlWeb.Api.V1.TelemetryController do
  use HttpToHtmlWeb, :controller

  alias HttpToHtmlWeb.TelemetryChannel

  def create(conn, %{"telemetry" => telemetry_params}) do
    TelemetryChannel.broadcast_all("new_reading", telemetry_params)

    conn
    |> put_status(:created)
    |> render("show.json", params: telemetry_params)
  end
end
