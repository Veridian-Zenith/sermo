defmodule SermoWeb.Presence do
  @moduledoc """
  Presence tracking for online/offline user status.
  """
  use Phoenix.Presence,
    otp_app: :sermo,
    pubsub_server: Sermo.PubSub
end
