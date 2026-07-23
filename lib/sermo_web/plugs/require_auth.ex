defmodule SermoWeb.Plugs.RequireAuth do
  @moduledoc """
  Plug for requiring authenticated users.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if Map.get(conn.assigns, :current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You must log in first")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
