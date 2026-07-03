defmodule SermoWeb.LoginLive do
  use SermoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, csrf_token: Plug.CSRFProtection.get_csrf_token())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full flex items-center justify-center bg-primary">
        <div class="w-full max-w-sm mx-4 p-8 card">
          <h1 class="text-3xl font-black text-center mb-1 text-gradient select-none">Sermo</h1>
          <p class="text-sm text-secondary text-center mb-8 select-none tracking-wider uppercase">conversation platform</p>
          <form action="/session" method="post" class="space-y-4">
            <input type="hidden" name="_csrf_token" value={@csrf_token} />
            <div>
              <label for="username" class="label">Username</label>
              <input type="text" name="username" id="username" required class="input-field mt-1" />
            </div>
            <div>
              <label for="password" class="label">Password</label>
              <input type="password" name="password" id="password" required class="input-field mt-1" />
            </div>
            <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
              Enter
            </button>
          </form>
          <p class="text-center text-sm mt-4 text-secondary">
            <.link href="/recover" class="text-accent font-semibold hover-bright transition">Forgot password?</.link>
          </p>
          <p class="text-center text-sm mt-4 text-secondary">
            No account?
            <.link href="/register" class="text-accent font-semibold hover-bright transition">Create one</.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
