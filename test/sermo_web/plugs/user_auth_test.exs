defmodule SermoWeb.UserAuthTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "call/2" do
    test "sets current_user when session has valid user_id", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> SermoWeb.UserAuth.call(%{})

      assert conn.assigns.current_user.id == user.id
    end

    test "sets current_user to nil when no session", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> SermoWeb.UserAuth.call(%{})

      refute conn.assigns.current_user
    end
  end

  describe "login/2" do
    test "sets session and assigns", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> SermoWeb.UserAuth.login(user)

      assert get_session(conn, :user_id) == user.id
      assert conn.assigns.current_user.id == user.id
    end
  end

  describe "logout/1" do
    test "drops session and clears assigns", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> SermoWeb.UserAuth.logout()

      refute conn.assigns.current_user
      assert conn.private[:plug_session_info] == :drop
    end
  end
end
