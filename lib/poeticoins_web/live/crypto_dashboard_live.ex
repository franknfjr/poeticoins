defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product

  @impl true
  def mount(_params, _session, socket) do
    products = Poeticoins.available_products()

    trades =
      products
      |> Poeticoins.get_last_trades()
      |> Enum.reject(&is_nil(&1))
      |> Enum.map(&{&1.product, &1})
      |> Enum.into(%{})

    if connected?(socket) do
      Enum.each(products, &Poeticoins.subscribe_to_trades(&1))
    end

    socket = assign(socket, trades: trades, products: products)
    {:ok, socket}
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> update(:trades, &Map.put(&1, trade.product, trade))
      |> assign(:page_title, "#{trade.price}")

    {:noreply, socket}
  end
end
