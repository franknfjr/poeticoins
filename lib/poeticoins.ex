defmodule Poeticoins do
  @moduledoc """
  Poeticoins keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defdelegate available_products(), to: Poeticoins.Exchanges
  defdelegate subscribe_to_trades(product), to: Poeticoins.Exchanges, as: :subscribe

  defdelegate unsubcribe_from_trades(product), to: Poeticoins.Exchanges, as: :unsubscribe

  defdelegate get_last_trade(product), to: Poeticoins.Historical
  defdelegate get_last_trades(products), to: Poeticoins.Historical
end
