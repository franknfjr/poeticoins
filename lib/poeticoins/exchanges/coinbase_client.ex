defmodule Poeticoins.Exchanges.CoinbaseClient do
  use GenServer
  alias Poeticoins.{Trade, Product}
  @exchange_name "coinbase"

  def start_link(currency_pairs, opts \\ []) do
    GenServer.start_link(__MODULE__, currency_pairs, opts)
  end

  def init(currency_pairs) do
    state = %{
      currency_pairs: currency_pairs,
      conn: nil
    }

    {:ok, state, {:continue, :connect}}
  end

  def subscribe(state) do
    state.currency_pairs
    |> subscription_frames()
    |> Enum.each(&:gun.ws_send(state.conn, &1))
  end

  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    trade =
      msg
      |> message_to_trade()
      |> IO.inspect(label: "trade")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  def message_to_trade(msg) do
    currency_pair = msg["product_id"]

    Trade.new(
      product: Product.new(@exchange_name, currency_pair),
      price: msg["price"],
      volume: msg["last_size"],
      traded_at: datetime_from_string(msg["time"])
    )
  end

  def handle_info({:gun_up, conn, :http}, %{conn: conn} = state) do
    :gun.ws_upgrade(state.conn, "/")
    {:noreply, state}
  end

  def handle_info(
        {:gun_upgrade, conn, _ref, ["websocket"], _headers},
        %{conn: conn} = state
      ) do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info(
        {:gun_ws, conn, _ref, {:text, msg} = _frame},
        %{conn: conn} = state
      ) do
    msg
    |> Jason.decode!()
    |> handle_ws_message(state)
  end

  def handle_continue(:connect, state) do
    updated_state = connect(state)
    {:noreply, updated_state}
  end

  def connect(state) do
    {:ok, conn} = :gun.open(server_host(), server_port(), conn_opts())
    %{state | conn: conn}
  end

  defp subscription_frames(currency_pairs) do
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  defp server_host, do: 'ws-feed.exchange.coinbase.com'
  defp server_port, do: 443

  defp conn_opts do
    %{
      protocols: [:http],
      transport: :tls,
      transport_opts: [
        verify: :verify_peer,
        cacertfile: :certifi.cacertfile(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    }
  end

  defp datetime_from_string(time_string) do
    {:ok, dt, _} = DateTime.from_iso8601(time_string)
    dt
  end
end
