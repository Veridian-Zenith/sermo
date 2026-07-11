defmodule SermoWeb.RegistrationControllerTest do
  use SermoWeb.ConnCase, async: false

  import Sermo.Fixtures

  describe "POST /register" do
    test "registers a user, mints recovery keys, and redirects", %{conn: conn} do
      username = unique_username()

      conn =
        post(conn, ~p"/register", %{
          username: username,
          password: "password123",
          display_name: "New Person"
        })

      assert redirected_to(conn) =~ ~p"/recovery-keys"
      assert get_session(conn, :user_id) != nil

      user = Sermo.Accounts.get_user_by_username(username)
      assert user
      assert Sermo.Accounts.has_recovery_keys?(user)
    end

    test "re-renders errors for invalid input and stays on /register", %{conn: conn} do
      conn =
        post(conn, ~p"/register", %{
          username: "",
          password: "123"
        })

      assert redirected_to(conn) == ~p"/register"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) != nil
    end
  end
end
