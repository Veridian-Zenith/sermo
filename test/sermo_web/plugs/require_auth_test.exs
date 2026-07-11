defmodule SermoWeb.Plugs.RequireAuthTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  test "halts and redirects to /login when unauthenticated" do
    conn =
      build_conn(:get, "/chat")
      |> Plug.Test.init_test_session(%{})
      |> Phoenix.Controller.fetch_flash([])

    conn = SermoWeb.Plugs.RequireAuth.call(conn, [])

    assert conn.halted
    assert redirected_to(conn) == ~p"/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "log in"
  end

  test "passes through when authenticated" do
    user = create_user()
    conn = build_conn(:get, "/chat") |> assign(:current_user, user)
    conn = SermoWeb.Plugs.RequireAuth.call(conn, [])

    refute conn.halted
  end
end
