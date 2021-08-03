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
    %{"payload" => readings, "subscriber" => subscriber_id} = payload

    subscriber = %{
      id: subscriber_id,
      data: readings
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
    update_subscriber_aux([], subscribers, subscriber, false)
  end

  defp update_subscriber_aux([], [], subscriber, _), do: [subscriber]
  defp update_subscriber_aux(acc, [], subscriber, false), do: acc ++ [subscriber]
  defp update_subscriber_aux(acc, [], _subscriber, true), do: acc
  defp update_subscriber_aux(acc, lst, _subscriber, true), do: acc ++ lst
  defp update_subscriber_aux(acc, [h], subscriber, false) do
    if h.id == subscriber.id do
      updated_sub = h |> Map.put(:data, h.data ++ subscriber.data)
      update_subscriber_aux(acc ++ [updated_sub], [], subscriber, true)
    else
      update_subscriber_aux(acc ++ [h], [], subscriber, false)
    end
  end
  defp update_subscriber_aux(acc, [h | t], subscriber, false) do
    if h.id == subscriber.id do
      updated_sub = h |> Map.put(:data, h.data ++ subscriber.data)
      update_subscriber_aux(acc ++ [updated_sub], t, subscriber, true)
    else
      update_subscriber_aux(acc ++ [h], t, subscriber, false)
    end
  end
end
