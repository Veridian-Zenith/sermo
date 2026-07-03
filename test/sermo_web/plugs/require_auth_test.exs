defmodule SermoWeb.Plugs.RequireAuthTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  test "allows authenticated user through", %{conn: conn} do
    user = create_user()

    conn =
      conn
      |> Plug.Test.init_test_session(%{user_id: user.id})
      |> SermoWeb.UserAuth.call(%{})
      |> SermoWeb.Plugs.RequireAuth.call(%{})

    assert conn.halted == false
    assert conn.assigns.current_user.id == user.id
  end

  test "redirects unauthenticated user", %{conn: conn} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> fetch_flash()
      |> assign(:current_user, nil)
      |> SermoWeb.Plugs.RequireAuth.call(%{})

    assert conn.halted
    assert redirected_to(conn) == "/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You must log in first"
  end
end
