defmodule SermoWeb.API.RegistrationControllerTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "POST /api/v1/register" do
    test "creates a user and returns token", %{conn: conn} do
      username = unique_username()

      conn =
        post(conn, ~p"/api/v1/register", %{
          username: username,
          password: "password123",
          display_name: "Test User"
        })

      assert json_response(conn, 201)
      assert conn.resp_body =~ username
      assert conn.resp_body =~ "token"
    end

    test "returns errors for invalid input", %{conn: conn} do
      conn =
        post(conn, ~p"/api/v1/register", %{
          username: "",
          password: "123"
        })

      assert json_response(conn, 422)
      assert conn.resp_body =~ "error"
    end
  end
end
