defmodule HttpToHtmlWeb.PageLive do
  use HttpToHtmlWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(HttpToHtml.PubSub, "telemetry:lobby")
    {:ok,
      socket
      |> assign(:subscribers, [])
    }
  end

  @impl true
  def handle_info(%{:event => "new_reading", :payload => payload}, socket) do
    %{"payload" => payload, "subscriber" => subscriber_id} = payload

    subscriber = %{
      id: subscriber_id,
      data: [payload]
    }

    subscribers = update_subscriber(socket.assigns.subscribers, subscriber)

    {
      :noreply,
      socket
      |> assign(:subscribers, subscribers)
      |> put_flash(:info, "NEW TELEMETRY READING")
    }
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  defp update_subscriber([], subscriber), do: [subscriber]
  defp update_subscriber(subscribers, subscriber) do
    update_subscriber_aux([], subscribers, subscriber)
  end

  defp update_subscriber_aux([], [], subscriber), do: [subscriber]
  defp update_subscriber_aux(acc, [], subscriber), do: acc
  defp update_subscriber_aux(acc, [h], subscriber) do
    if h.id == subscriber.id do
      updated_sub = h |> Map.put(:data, h.data ++ subscriber.data)
      update_subscriber_aux(acc ++ [updated_sub], [], subscriber)
    else
      update_subscriber_aux(acc ++ [h, subscriber], [], subscriber)
    end
  end
  defp update_subscriber_aux(acc, [h | t], subscriber) do
    if h.id == subscriber.id do
      updated_sub = h |> Map.put(:data, h.data ++ subscriber.data)
      update_subscriber_aux(acc ++ [updated_sub], t, subscriber)
    else
      update_subscriber_aux(acc ++ [h], t, subscriber)
    end
  end
end
