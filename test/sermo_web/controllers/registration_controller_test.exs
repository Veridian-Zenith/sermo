defmodule SermoWeb.RegistrationControllerTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "POST /register" do
    test "creates user and redirects to recovery keys", %{conn: conn} do
      username = unique_username()

      conn =
        post(conn, ~p"/register", %{
          username: username,
          password: "password123",
          display_name: "Test User"
        })

      assert redirected_to(conn) =~ "/recovery-keys?token="
    end

    test "returns errors for invalid input", %{conn: conn} do
      conn =
        post(conn, ~p"/register", %{
          username: "",
          password: "123"
        })

      assert redirected_to(conn) == "/register"
      assert Phoenix.Flash.get(conn.assigns.flash, :error)
    end
  end
end
