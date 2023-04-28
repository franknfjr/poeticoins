defmodule PoeticoinsWeb.ProductLive do
  use PoeticoinsWeb, :live_view
  import PoeticoinsWeb.ProductHelpers

  def mount(%{"id" => product_id} = _params, _session, socket) do
    product = product_from_string(product_id)
    trade = Poeticoins.get_last_trade(product)
    trades = get_trade_history()

    socket =
      assign(socket,
        product: product,
        product_id: product_id,
        trade: trade,
        trades: trades,
        page_title: page_title_from_trade(trade)
      )

    if socket.connected? do
      Poeticoins.subscribe_to_trades(product)
    end

    {:ok, socket, temporary_assigns: [trades: []]}
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <div class="row">
      <div class="column"
          phx-hook="HighChart"
          phx-update="ignore"
          id="product-chart"
          data-product-id="<%= to_string(@product) %>"
          data-product-name="<%= @product.exchange_name %> <%= @product.currency_pair %>"
          data-trade-timestamp="<%= DateTime.to_unix(@trade.traded_at, :millisecond) %>"
          data-trade-volume="<%= @trade.volume %>"
          data-trade-price="<%= @trade.price %>"
      >
        <div id="stockchart-container"></div>
      </div>
    </div>
      <h1><%= fiat_character(@product) %> <%= @trade.price %></h1>
      <table>

    <thead>
    <th>Traded at</th>
    <th>Exchange</th>
    <th>Currency</th>
    <th>Price</th>
    <th>Volume</th>
    </thead>

    <tbody phx-hook="TradeHistory"
    phx-update="prepend"
    id="trade-history-rows">
    <%= for trade <- @trades, not is_nil(trade) do%>

    <tr id="trade-<%= timestamp(@trade.traded_at) %>">
      <td><%= human_datetime(@trade.traded_at) %></td>
      <td><%= trade.product.exchange_name %></td>
      <td><%= trade.product.currency_pair %></td>
      <td><%= trade.price %></td>
      <td><%= trade.volume %></td>
    </tr>

    <% end %>
    </tbody>
    </table>
    </div>
    """
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> ...</h1>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
      |> assign(:page_title, page_title_from_trade(trade))
      |> update(:trades, &[trade | &1])

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{fiat_character(trade.product)}#{trade.price}" <>
      " #{trade.product.currency_pair} #{trade.product.exchange_name}"
  end

  defp timestamp(dt) do
    DateTime.to_unix(dt, :millisecond)
  end

  defp get_trade_history, do: []
end
