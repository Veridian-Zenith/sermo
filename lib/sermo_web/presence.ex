defmodule SermoWeb.Presence do
  use Phoenix.Presence,
    otp_app: :sermo,
    pubsub_server: Sermo.PubSub
end
