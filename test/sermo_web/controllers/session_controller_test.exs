defmodule SermoWeb.SessionControllerTest do
  use SermoWeb.ConnCase, async: false

  import Sermo.Fixtures

  describe "POST /session" do
    test "logs in with valid credentials and redirects to /chat", %{conn: conn} do
      user = create_user()

      conn =
        post(conn, ~p"/session", %{
          username: user.username,
          password: "password123"
        })

      assert redirected_to(conn) == ~p"/chat"
      assert get_session(conn, :user_id) == user.id
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome"
    end

    test "rejects invalid credentials and redirects to /login", %{conn: conn} do
      create_user()

      conn =
        post(conn, ~p"/session", %{
          username: "anyone",
          password: "wrong"
        })

      assert redirected_to(conn) == ~p"/login"
      assert get_session(conn, :user_id) == nil
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid"
    end
  end

  describe "GET /logout" do
    test "clears the session and redirects to /login", %{conn: conn} do
      user = create_user()
      conn = post(conn, ~p"/session", %{username: user.username, password: "password123"})
      assert get_session(conn, :user_id) == user.id

      conn = get(conn, ~p"/logout")

      assert redirected_to(conn) == ~p"/login"

      # The session must be genuinely cleared: a protected route now bounces
      # back to the login page.
      conn = get(conn, ~p"/chat")
      assert redirected_to(conn) == ~p"/login"
    end
  end
end
