defmodule SermoWeb.API.SessionControllerTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "POST /api/v1/session" do
    test "authenticates and returns token", %{conn: conn} do
      user = create_user()

      conn =
        post(conn, ~p"/api/v1/session", %{
          username: user.username,
          password: "password123"
        })

      assert %{"data" => %{"token" => _token, "user" => %{"username" => username}}} =
               json_response(conn, 200)

      assert username == user.username
    end

    test "returns error for invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/api/v1/session", %{
          username: "nobody",
          password: "wrong"
        })

      assert %{"errors" => _} = json_response(conn, 401)
    end
  end

  describe "DELETE /api/v1/session" do
    test "voids a valid session", %{conn: conn} do
      user = create_user()

      conn =
        post(conn, ~p"/api/v1/session", %{
          username: user.username,
          password: "password123"
        })

      assert %{"data" => %{"token" => token}} = json_response(conn, 200)

      conn2 =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/api/v1/session")

      assert json_response(conn2, 200)
    end
  end
end
