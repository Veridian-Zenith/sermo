defmodule SermoWeb.SessionControllerTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "POST /session" do
    test "logs in with valid credentials", %{conn: conn} do
      user = create_user()

      conn =
        post(conn, ~p"/session", %{
          username: user.username,
          password: "password123"
        })

      assert redirected_to(conn) == "/chat"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Welcome back!"
    end

    test "rejects invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/session", %{
          username: "nobody",
          password: "wrong"
        })

      assert redirected_to(conn) == "/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid username or password"
    end
  end

  describe "GET /logout" do
    test "logs out authenticated user", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(~p"/logout")

      assert redirected_to(conn) == "/login"
      assert conn.private[:plug_session_info] == :drop
    end
  end
end
