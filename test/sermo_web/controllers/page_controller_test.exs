defmodule SermoWeb.PageControllerTest do
  use SermoWeb.ConnCase, async: true

  import Sermo.Fixtures

  describe "GET /" do
    test "renders landing page for unauthenticated users", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Sermo"
      assert html_response(conn, 200) =~ "Create Account"
    end

    test "redirects to chat for authenticated users", %{conn: conn} do
      user = create_user()

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(~p"/")

      assert redirected_to(conn) == "/chat"
    end
  end
end
