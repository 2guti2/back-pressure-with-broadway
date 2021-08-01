defmodule HttpToHtmlWeb.Api.V1.TelemetryView do
  use HttpToHtmlWeb, :view
  alias HttpToHtmlWeb.Api.V1.TelemetryView

  def render("show.json", %{params: params}) do
    %{payload: params}
  end
end
