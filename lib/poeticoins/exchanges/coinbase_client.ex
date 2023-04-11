defmodule Poeticoins.Exchanges.CoinbaseClient do
  alias Poeticoins.Exchanges.Client
  alias Poeticoins.{Trade, Product}
  import Client, only: [validate_required: 2]
  @behaviour Client

  @exchange_name "coinbase"
  @required_fields ~w(product_id time price last_size)

  @impl true
  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    _trade =
      msg
      |> message_to_trade()
      |> IO.inspect(label: "trade")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, @required_fields),
         {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"]) do
      currency_pair = msg["product_id"]

      Trade.new(
        product: Product.new(exchange_name(), currency_pair),
        price: msg["price"],
        volume: msg["last_size"],
        traded_at: traded_at
      )
    else
      {:error, _reason} = error -> error
    end
  end

  @impl true
  def subscription_frames(currency_pairs) do
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end

  @impl true
  def exchange_name, do: @exchange_name

  @impl true
  def server_host, do: 'ws-feed.exchange.coinbase.com'

  @impl true
  def server_port, do: 443
end
