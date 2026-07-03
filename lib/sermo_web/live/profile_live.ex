defmodule SermoWeb.ProfileLive do
  use SermoWeb, :live_view

  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(:display_name, current_user.display_name || "")
      |> assign(:bio, current_user.bio || "")
      |> assign(:social_links, current_user.social_links || %{})
      |> assign(:new_link_name, "")
      |> assign(:new_link_url, "")
      |> assign(:recovery_keys, Accounts.list_recovery_keys(current_user))
      |> assign(:generated_keys, nil)
      |> assign_password_form()
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 1,
        max_file_size: 5_000_000
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="h-full overflow-y-auto bg-primary">
        <div class="max-w-xl lg:max-w-4xl mx-auto p-6 space-y-6">
          <div class="flex items-center gap-3 mb-2">
            <.link href="/chat" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs no-underline">← Back</.link>
            <h1 class="text-2xl font-black text-gradient">Profile</h1>
          </div>

          <div class="lg:grid lg:grid-cols-2 gap-6 items-start">
            <div class="space-y-6">
              <div class="p-6 card space-y-4">
                <h2 class="label">Avatar</h2>
                <div class="flex items-center gap-4">
                  <div class="w-16 h-16 rounded-full bg-secondary border border-[var(--vz-border-color)] overflow-hidden shrink-0 flex items-center justify-center shadow-glow-sm">
                    <%= if @current_user.avatar_path do %>
                      <img src={~p"/uploads/avatars/#{@current_user.avatar_path}"} class="w-full h-full cover" />
                    <% else %>
                      <span class="text-lg font-bold text-muted"><%= String.first(@current_user.display_name || @current_user.username) |> String.upcase() %></span>
                    <% end %>
                  </div>
                  <form phx-submit="save-avatar" phx-change="validate-avatar" class="flex-1">
                    <.live_file_input upload={@uploads.avatar} class="input-field text-sm" />
                    <button :for={_e <- @uploads.avatar.entries} type="submit" class="btn btn-primary rounded-xl px-4 py-1.5 text-xs mt-2">
                      Upload
                    </button>
                  </form>
                  <button :if={@current_user.avatar_path} phx-click="remove-avatar"
                    class="text-xs text-muted underline shrink-0 self-end mb-1">
                    remove
                  </button>
                </div>
                <div :for={err <- @uploads.avatar.errors} class="text-xs text-red-400"><%= inspect(err) %></div>
              </div>

              <div class="p-6 card space-y-4">
                <h2 class="label">Display Name</h2>
                <form phx-submit="save-display-name" class="space-y-3">
                  <input type="text" name="display_name" value={@display_name} placeholder="set a display name"
                    class="input-field" />
                  <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
                    Save
                  </button>
                </form>
              </div>

              <div class="p-6 card space-y-4">
                <h2 class="label">Bio</h2>
                <form phx-submit="save-bio" class="space-y-3">
                  <textarea name="bio" rows="3" placeholder="tell the world about yourself" maxlength="500"
                    class="input-field resize-none"><%= @bio %></textarea>
                  <div class="text-xs text-muted text-right"><%= String.length(@bio) %>/500</div>
                  <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
                    Save Bio
                  </button>
                </form>
              </div>
            </div>

            <div class="space-y-6">
              <div class="p-6 card space-y-4">
                <h2 class="label">Links</h2>
                <div class="space-y-2">
                  <div :for={{name, url} <- @social_links} class="flex items-center gap-2 text-sm bg-secondary/50 rounded-xl px-3 py-2">
                    <span class="font-semibold text-accent shrink-0"><%= name %></span>
                    <span class="text-muted truncate flex-1"><%= url %></span>
                    <button phx-click="remove-link" phx-value-name={name} class="text-xs text-muted hover-bright transition shrink-0">×</button>
                  </div>
                  <div :if={@social_links == %{}} class="text-xs text-muted">no links added yet</div>
                </div>
                <form phx-submit="add-link" class="flex gap-2 items-end">
                  <input type="text" name="name" value={@new_link_name} placeholder="label (e.g. GitHub)"
                    class="input-field text-sm flex-1" />
                  <input type="url" name="url" value={@new_link_url} placeholder="https://..."
                    class="input-field text-sm flex-2" />
                  <button type="submit" class="btn btn-primary rounded-xl px-3 py-2 text-xs shrink-0">
                    Add
                  </button>
                </form>
              </div>

              <div class="p-6 card space-y-4 text-center">
                <h2 class="label text-left">Public Profile Preview</h2>
                <div class="w-16 h-16 rounded-full bg-secondary border border-[var(--vz-border-color)] overflow-hidden mx-auto flex items-center justify-center">
                  <%= if @current_user.avatar_path do %>
                    <img src={~p"/uploads/avatars/#{@current_user.avatar_path}"} class="w-full h-full cover" />
                  <% else %>
                    <span class="text-lg font-bold text-muted"><%= String.first(@current_user.display_name || @current_user.username) |> String.upcase() %></span>
                  <% end %>
                </div>
                <div>
                  <div class="font-semibold text-white"><%= @current_user.display_name || @current_user.username %></div>
                  <div class="text-xs text-muted">@<%= @current_user.username %></div>
                </div>
                <div :if={@current_user.bio} class="text-xs text-secondary leading-relaxed"><%= @current_user.bio %></div>
                <div :if={@current_user.social_links && @current_user.social_links != %{}} class="flex flex-wrap justify-center gap-2">
                  <a :for={{name, url} <- @current_user.social_links} href={url} target="_blank"
                    class="text-xs text-accent font-semibold hover-bright transition no-underline"><%= name %></a>
                </div>
              </div>

              <div class="p-6 card space-y-4">
                <h2 class="label">Change Password</h2>
                <form phx-submit="change-password" class="space-y-3">
                  <input type="password" name="password" placeholder="new password (min 6 chars)"
                    class="input-field" />
                  <button type="submit" class="btn btn-primary w-full py-3 rounded-xl text-sm">
                    Update Password
                  </button>
                </form>
              </div>

              <div class="p-6 card space-y-4">
                <h2 class="label">Recovery Keys</h2>
                <p class="text-xs text-secondary leading-relaxed">
                  recovery keys let you reset your password without email.
                  save them somewhere safe — they are shown only once.
                </p>
                <div :if={@generated_keys} class="space-y-2">
                  <p class="text-xs text-accent font-semibold">new keys generated — save them now:</p>
                  <div :for={k <- @generated_keys} class="px-3 py-2 rounded bg-secondary/50 font-mono text-sm text-white tracking-wider text-center select-all">
                    <%= k.key %>
                  </div>
                  <button phx-click="dismiss-keys"
                    class="btn btn-ghost w-full rounded-xl py-2 text-xs mt-2">
                    I've saved them
                  </button>
                </div>
                <div :if={!@generated_keys} class="flex items-center justify-between">
                  <div class="space-y-1">
                    <div class="text-xs text-muted">
                      <%= length(Enum.filter(@recovery_keys, &(!&1.used))) %> unused /
                      <%= length(@recovery_keys) %> total
                    </div>
                    <div :if={has_unused?(@recovery_keys)} class="text-xs text-muted">
                      keys work even if you forget your password
                    </div>
                  </div>
                  <button phx-click="generate-keys"
                    class="btn btn-primary rounded-xl px-4 py-2 text-xs shrink-0">
                    <%= if @recovery_keys == [], do: "Generate", else: "Regenerate" %>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="text-xs text-muted text-center pb-6">
            logged in as <span class="text-white font-semibold">@<%= @current_user.username %></span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate-avatar", _, socket) do
    {:noreply, socket}
  end

  def handle_event("save-avatar", _, socket) do
    avatar = socket.assigns.current_user

    result =
      consume_uploaded_entries(socket, :avatar, fn meta, entry ->
        ext = Path.extname(entry.client_name)
        filename = "#{avatar.id}#{ext}"
        dest = Application.app_dir(:sermo, "priv/static/uploads/avatars")
        File.mkdir_p!(dest)
        File.cp!(meta.path, Path.join(dest, filename))
        {:ok, filename}
      end)

    case result do
      [filename] ->
        case Accounts.update_user(avatar, %{avatar_path: filename}) do
          {:ok, user} ->
            {:noreply,
             socket
             |> assign(:current_user, user)
             |> put_flash(:info, "Avatar updated")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not update avatar")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "No file selected")}
    end
  end

  def handle_event("remove-avatar", _, socket) do
    case Accounts.update_user(socket.assigns.current_user, %{avatar_path: nil}) do
      {:ok, user} ->
        {:noreply, assign(socket, :current_user, user) |> put_flash(:info, "Avatar removed")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("save-display-name", %{"display_name" => display_name}, socket) do
    display_name = if display_name == "", do: nil, else: display_name

    case Accounts.update_user(socket.assigns.current_user, %{display_name: display_name}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:display_name, user.display_name || "")
         |> put_flash(:info, "Display name updated")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, extract_error(changeset))}
    end
  end

  def handle_event("save-bio", %{"bio" => bio}, socket) do
    case Accounts.update_user(socket.assigns.current_user, %{bio: bio}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:bio, user.bio || "")
         |> put_flash(:info, "Bio updated")}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, extract_error(changeset))}
    end
  end

  def handle_event("add-link", %{"name" => name, "url" => url}, socket) do
    name = String.trim(name)
    url = String.trim(url)

    if name == "" or url == "" do
      {:noreply, put_flash(socket, :error, "Both name and URL are required")}
    else
      links = Map.put(socket.assigns.social_links, name, url)

      case Accounts.update_user(socket.assigns.current_user, %{social_links: links}) do
        {:ok, user} ->
          {:noreply,
           socket
           |> assign(:current_user, user)
           |> assign(:social_links, user.social_links || %{})
           |> assign(:new_link_name, "")
           |> assign(:new_link_url, "")
           |> put_flash(:info, "Link added")}

        {:error, _} ->
          {:noreply, socket}
      end
    end
  end

  def handle_event("remove-link", %{"name" => name}, socket) do
    links = Map.delete(socket.assigns.social_links, name)

    case Accounts.update_user(socket.assigns.current_user, %{social_links: links}) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:social_links, user.social_links || %{})}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("change-password", %{"password" => password}, socket) do
    if password == "" do
      {:noreply, put_flash(socket, :error, "Password cannot be empty")}
    else
      case Accounts.change_password(socket.assigns.current_user, %{password: password}) do
        {:ok, _user} ->
          {:noreply, socket |> assign_password_form() |> put_flash(:info, "Password changed")}

        {:error, changeset} ->
          {:noreply, put_flash(socket, :error, extract_error(changeset))}
      end
    end
  end

  def handle_event("generate-keys", _, socket) do
    user = socket.assigns.current_user

    {:ok, keys} = Accounts.generate_recovery_keys(user, 3)

    {:noreply,
     socket
     |> assign(:generated_keys, keys)
     |> assign(:recovery_keys, Accounts.list_recovery_keys(user))
     |> put_flash(:info, "Recovery keys generated — save them now")}
  end

  def handle_event("dismiss-keys", _, socket) do
    {:noreply, assign(socket, :generated_keys, nil)}
  end

  defp has_unused?(keys) do
    Enum.any?(keys, &(!&1.used))
  end

  defp assign_password_form(socket) do
    assign(socket, password: "")
  end

  defp extract_error(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end)
    |> Enum.map_join(", ", fn {field, msgs} -> "#{field}: #{Enum.join(msgs, ", ")}" end)
  end
end
