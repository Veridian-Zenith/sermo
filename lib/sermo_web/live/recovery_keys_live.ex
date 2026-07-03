defmodule SermoWeb.RecoveryKeysLive do
  use SermoWeb, :live_view

  alias Sermo.Accounts

  @token_max_age 86_400

  def mount(params, session, socket) do
    user = Accounts.get_user(session["user_id"])
    keys = parse_token(params["token"])

    if keys do
      socket =
        socket
        |> assign(:current_user, user)
        |> assign(:keys, keys)
        |> assign(:download_token, params["token"])

      {:ok, socket}
    else
      {:ok, push_navigate(socket, to: ~p"/chat")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full flex items-center justify-center bg-primary overflow-y-auto">
        <div class="w-full max-w-lg mx-4 p-8 card space-y-6">
          <div class="text-center">
            <div class="text-4xl mb-2">🔑</div>
            <h1 class="text-2xl font-black text-gradient">Recovery Keys</h1>
            <p class="text-sm text-secondary mt-2 leading-relaxed">
              these keys can reset your password if you ever get locked out.<br />
              <span class="text-accent font-semibold">save them now — shown only once.</span>
            </p>
          </div>

          <div class="space-y-2">
            <div :for={k <- @keys} class="px-4 py-3 rounded-2xl bg-secondary/50 border border-[var(--vz-border-color)]">
              <code class="font-mono text-sm text-white tracking-wider select-all"><%= k.key %></code>
            </div>
          </div>

          <div class="flex flex-col gap-3">
            <a href={~p"/recovery-keys/download?token=#{@download_token}"}
              class="btn btn-primary w-full py-3 rounded-xl text-sm text-center no-underline">
              Download .txt
            </a>
            <a href={~p"/chat"}
              class="btn btn-ghost w-full py-3 rounded-xl text-sm text-center no-underline">
              I've saved them — continue to chat
            </a>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp parse_token(nil), do: nil

  defp parse_token(token) do
    case Phoenix.Token.verify(SermoWeb.Endpoint, "recovery-download", token,
           max_age: @token_max_age
         ) do
      {:ok, data} -> decode_keys(data)
      _ -> nil
    end
  end

  defp decode_keys(data) when is_binary(data) do
    parts = String.split(data, "|")

    keys =
      Enum.map(parts, fn part ->
        case String.split(part, ":", parts: 2) do
          [_, key] -> %{key: key}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if keys == [], do: nil, else: keys
  end

  defp decode_keys(_), do: nil
end
