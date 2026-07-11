defmodule SermoWeb.API.AuthTest do
  use SermoWeb.ConnCase, async: false

  import Sermo.Fixtures

  test "authenticates a valid bearer token" do
    user = create_user()
    token = SermoWeb.API.Auth.generate_token(user)

    conn =
      build_conn(:get, "/api/v1/session")
      |> put_req_header("authorization", "Bearer #{token}")
      |> SermoWeb.API.Auth.call([])

    assert conn.assigns.api_user.id == user.id
  end

  test "rejects a missing token" do
    conn = build_conn(:get, "/api/v1/session") |> SermoWeb.API.Auth.call([])
    assert conn.assigns.api_user == nil
  end

  test "rejects an invalid token" do
    conn =
      build_conn(:get, "/api/v1/session")
      |> put_req_header("authorization", "Bearer not-a-token")
      |> SermoWeb.API.Auth.call([])

    assert conn.assigns.api_user == nil
  end

  test "require_auth halts with 401 when unauthenticated" do
    conn =
      build_conn(:get, "/api/v1/session")
      |> SermoWeb.API.Auth.require_auth([])

    assert conn.halted
    assert conn.status == 401
  end

  test "require_auth passes through when authenticated" do
    user = create_user()

    conn =
      build_conn(:get, "/api/v1/session")
      |> assign(:api_user, user)
      |> SermoWeb.API.Auth.require_auth([])

    refute conn.halted
  end
end
