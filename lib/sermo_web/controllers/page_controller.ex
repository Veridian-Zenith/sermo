defmodule SermoWeb.PageController do
  use SermoWeb, :controller

  def index(conn, _params) do
    if conn.assigns.current_user do
      redirect(conn, to: "/chat")
    else
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, landing_page())
    end
  end

  defp landing_page do
    """
    <!DOCTYPE html>
    <html lang="en" class="dark">
    <head>
      <meta charset="utf-8"/>
      <meta name="viewport" content="width=device-width,initial-scale=1"/>
      <title>Sermo</title>

      <style>
        @font-face { font-family: 'Rosemary'; src: url('/fonts/Rosemary.ttf') format('truetype'); font-weight: normal; font-style: normal; font-display: swap; }
        body { margin: 0; font-family: Rosemary, system-ui, sans-serif; background: #050200; color: #f3f4f6; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .landing { text-align: center; max-width: 28rem; padding: 2rem; }
        h1 { font-size: 3.5rem; font-weight: 900; margin: 0; background: linear-gradient(135deg, #FFB347, #D72638, #FFB347); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
        p { color: #d1d5db; margin: 1rem 0 2rem; line-height: 1.6; }
        .actions { display: flex; flex-direction: column; gap: 0.75rem; }
        .btn { display: block; padding: 0.75rem 1.5rem; border-radius: 1rem; font-family: inherit; font-size: 0.875rem; font-weight: 700; text-decoration: none; text-align: center; transition: all 0.2s ease; }
        .btn-primary { background: linear-gradient(135deg, #FFB347, #D72638); color: #000; }
        .btn-primary:hover { box-shadow: 0 0 25px rgba(255, 179, 71, 0.8); transform: scale(1.02); }
        .btn-ghost { color: #d1d5db; border: 1px solid rgba(255, 179, 71, 0.3); }
        .btn-ghost:hover { border-color: #FFB347; color: #FFB347; }
      </style>
    </head>
    <body>
      <div class="landing">
        <h1>Sermo</h1>
        <p>a conversation platform.<br/>private, lightweight, yours.</p>
        <div class="actions">
          <a href="/register" class="btn btn-primary">Create Account</a>
          <a href="/login" class="btn btn-ghost">Log In</a>
        </div>
      </div>
    </body>
    </html>
    """
  end
end
