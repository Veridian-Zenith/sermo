defmodule SermoWeb.PageController do
  use SermoWeb, :controller

  def index(conn, _params) do
    if conn.assigns.current_user do
      redirect(conn, to: "/chat")
    else
      redirect(conn, to: "/login")
    end
  end
end
