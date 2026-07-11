defmodule SermoWeb.PageControllerTest do
  use SermoWeb.ConnCase, async: false

  import Sermo.Fixtures

  test "GET / renders the landing page when logged out", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert conn.status == 200
    assert conn.resp_body =~ "Sermo"
  end

  test "GET / redirects to /chat when logged in", %{conn: conn} do
    user = create_user()
    conn = post(conn, ~p"/session", %{username: user.username, password: "password123"})

    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/chat"
  end
end
