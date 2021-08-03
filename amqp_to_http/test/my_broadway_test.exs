defmodule AmqpToHttpTest.MyBroadwayTest do
  use ExUnit.Case

  # very good candidate for property-based testing
  test "merges correctly" do
    messages = [%{
      subscriber: 20,
      payload: [%{"test" => 123}]
    },
    %{
      subscriber: 20,
      payload: [%{"test" => 123}]
    },
    %{
      subscriber: 40,
      payload: [%{"test" => 123}]
    }]

    expected_result = [
      %{
        subscriber: 20,
        payload: [
          %{"test" => 123}, %{"test" => 123}
        ]
      },
      %{
        subscriber: 40,
        payload: [
          %{"test" => 123}
        ]
      }
    ]

    result = MyBroadway.merge_payload_by_subscriber(messages)
    assert result == expected_result
  end
end