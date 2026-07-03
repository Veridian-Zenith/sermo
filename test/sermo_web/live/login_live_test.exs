defmodule SermoWeb.LoginLiveTest do
  use SermoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders login form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/login")
    assert view |> element("h1") |> render() =~ "Sermo"
    assert view |> element("form") |> render() =~ "Username"
  end
end
