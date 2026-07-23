defmodule SermoWeb.RecoverLive do
  use SermoWeb, :live_view

  alias Sermo.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, :username)
     |> assign(:username, "")
     |> assign(:recovery_key, "")
     |> assign(:new_password, "")
     |> assign(:error, nil)
     |> assign(:csrf_token, Plug.CSRFProtection.get_csrf_token())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full flex items-center justify-center bg-primary">
        <div class="w-full max-w-sm mx-4 p-8 card">
          <h1 class="text-2xl font-black text-center mb-1 text-gradient select-none">Recover Account</h1>
          <p class="text-sm text-secondary text-center mb-8 select-none tracking-wider uppercase">
            enter your recovery key to reset your password
          </p>

          <div :if={@step == :username} class="space-y-4">
            <p class="text-xs text-secondary text-center">Step 1 of 3</p>
            <div>
              <label for="username" class="label">Username</label>
              <input type="text" name="username" id="username" value={@username}
                phx-change="set-username" phx-keydown="next-on-enter" phx-key="Enter"
                class="input-field mt-1" autocomplete="off" />
            </div>
            <div :if={@error != nil and @step == :username} class="text-xs text-red-400 text-center"><%= @error %></div>
            <button phx-click="check-username" class="btn btn-primary w-full py-3 rounded-xl text-sm">
              Next
            </button>
          </div>

          <div :if={@step == :recovery_key} class="space-y-4">
            <p class="text-xs text-secondary text-center">Step 2 of 3</p>
            <p class="text-sm text-secondary text-center">
              account found. enter your recovery key
            </p>
            <div>
              <label for="recovery_key" class="label">Recovery Key</label>
              <input type="text" name="recovery_key" id="recovery_key" value={@recovery_key}
                placeholder="e.g. a3f1-9c0b-47d2-e85a"
                phx-change="set-key" phx-keydown="verify-on-enter" phx-key="Enter"
                class="input-field mt-1 text-center font-mono tracking-wider" autocomplete="off" />
            </div>
            <div :if={@error} class="text-xs text-red-400 text-center"><%= @error %></div>
            <button phx-click="verify-key" class="btn btn-primary w-full py-3 rounded-xl text-sm">
              Verify
            </button>
          </div>

          <div :if={@step == :new_password} class="space-y-4">
            <p class="text-xs text-secondary text-center">Step 3 of 3</p>
            <div>
              <label for="new_password" class="label">New Password (min 6 chars)</label>
              <input type="password" name="new_password" id="new_password" value={@new_password}
                phx-change="set-password" phx-keydown="recover-on-enter" phx-key="Enter"
                class="input-field mt-1" autocomplete="new-password" />
            </div>
            <div :if={@error} class="text-xs text-red-400 text-center"><%= @error %></div>
            <button phx-click="recover" class="btn btn-primary w-full py-3 rounded-xl text-sm">
              Reset Password
            </button>
          </div>

          <div :if={@step == :done} class="text-center space-y-4">
            <div class="text-lg text-green-400">✓</div>
            <p class="text-sm text-secondary">password reset successfully</p>
            <.link href="/login" class="btn btn-primary inline-block w-full py-3 rounded-xl text-sm mt-4 text-center">
              Log In
            </.link>
          </div>

          <p :if={@step != :done} class="text-center text-sm mt-6 text-secondary">
            Remember your password?
            <.link href="/login" class="text-accent font-semibold hover-bright transition">Log in</.link>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("set-username", %{"username" => username}, socket) do
    {:noreply, assign(socket, username: username, error: nil)}
  end

  def handle_event("next-on-enter", _, socket) do
    handle_event("check-username", %{}, socket)
  end

  def handle_event("check-username", _, socket) do
    username = String.trim(socket.assigns.username)

    if username == "" do
      {:noreply, assign(socket, error: "enter your username")}
    else
      handle_username_lookup(username, socket)
    end
  end

  def handle_event("set-key", %{"recovery_key" => key}, socket) do
    {:noreply, assign(socket, recovery_key: key, error: nil)}
  end

  def handle_event("verify-on-enter", _, socket) do
    handle_event("verify-key", %{}, socket)
  end

  def handle_event("verify-key", _, socket) do
    key = String.trim(socket.assigns.recovery_key)

    if key == "" do
      {:noreply, assign(socket, error: "enter your recovery key")}
    else
      case socket.assigns.recovering_user do
        nil ->
          {:noreply, assign(socket, step: :username, error: "session expired, start again")}

        _user ->
          {:noreply,
           socket
           |> assign(:step, :new_password)
           |> assign(:error, nil)}
      end
    end
  end

  def handle_event("set-password", %{"new_password" => password}, socket) do
    {:noreply, assign(socket, new_password: password, error: nil)}
  end

  def handle_event("recover-on-enter", _, socket) do
    handle_event("recover", %{}, socket)
  end

  def handle_event("recover", _, socket) do
    password = socket.assigns.new_password
    key = String.trim(socket.assigns.recovery_key)

    cond do
      password == "" ->
        {:noreply, assign(socket, error: "enter a new password")}

      String.length(password) < 6 ->
        {:noreply, assign(socket, error: "password must be at least 6 characters")}

      key == "" ->
        {:noreply, assign(socket, step: :recovery_key, error: "recovery key is required")}

      true ->
        handle_recovery(socket.assigns.username, key, password, socket)
    end
  end

  defp handle_username_lookup(username, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:noreply, assign(socket, error: "no account found with that username")}

      user ->
        if Accounts.has_recovery_keys?(user) do
          {:noreply,
           socket
           |> assign(:step, :recovery_key)
           |> assign(:recovering_user, user)
           |> assign(:error, nil)}
        else
          {:noreply, assign(socket, error: "this account has no recovery keys set up")}
        end
    end
  end

  defp handle_recovery(username, key, password, socket) do
    case Accounts.recover_account(username, key, password) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> assign(:step, :done)
         |> assign(:error, nil)}

      {:error, :invalid_username} ->
        {:noreply, assign(socket, step: :username, error: "account not found")}

      {:error, :invalid_recovery_key} ->
        {:noreply, assign(socket, step: :recovery_key, error: "invalid recovery key")}

      {:error, _} ->
        {:noreply, assign(socket, error: "recovery failed. try again")}
    end
  end
end
