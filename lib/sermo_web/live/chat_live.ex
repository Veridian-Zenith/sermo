defmodule SermoWeb.ChatLive do
  use SermoWeb, :live_view

  alias Sermo.Conversations
  alias Sermo.Accounts

  def mount(_params, session, socket) do
    current_user = Accounts.get_user(session["user_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sermo.PubSub, "user:#{current_user.id}")
    end

    conversations = Conversations.list_conversations(current_user.id)
    enriched = enrich_conversations(conversations, current_user.id)

    socket =
      socket
      |> assign(:current_user, current_user)
      |> assign(conversations: enriched, current_conversation_id: nil, new_message: "")
      |> stream(:messages, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex h-full bg-primary">
        <aside class="w-72 border-r flex flex-col bg-secondary overflow-x-hidden select-none">
          <div class="p-4 sidebar-header flex justify-between items-center">
            <h2 class="text-lg font-black text-gradient">Sermo</h2>
            <button phx-click="new-conversation" class="btn btn-ghost rounded-xl px-3 py-1.5 text-xs">
              + New
            </button>
          </div>
          <div class="flex-1 overflow-y-auto overflow-x-hidden">
            <div :for={conv <- @conversations}
              phx-click="select-conversation" phx-value-id={conv.id}
              class={"sidebar-item " <> (if @current_conversation_id == conv.id, do: "active", else: "")}>
              <div class="font-semibold text-sm text-white"><%= conv.display_name %></div>
              <div :if={conv.type == "group" && conv.name} class="text-xs text-muted mt-0.5"><%= conv.name %></div>
            </div>
            <div :if={@conversations == []} class="p-6 text-muted text-center text-sm">
              silence...
            </div>
          </div>
          <div class="p-3 sidebar-footer text-sm text-secondary flex justify-between items-center">
            <span class="font-medium"><%= @current_user.display_name || @current_user.username %></span>
            <.link href="/logout" class="text-xs text-accent font-semibold hover-bright transition">exit</.link>
          </div>
        </aside>
        <main class="flex-1 flex flex-col bg-primary">
          <div :if={@current_conversation_id == nil} class="flex-1 flex items-center justify-center">
            <div class="text-center">
              <div class="text-4xl font-black text-gradient select-none">Sermo</div>
              <p class="text-sm text-muted mt-2">select a conversation to begin</p>
            </div>
          </div>
          <div :if={@current_conversation_id != nil} class="flex-1 flex flex-col">
            <div id="messages" phx-update="stream" class="flex-1 overflow-y-auto p-4 space-y-3">
              <div :for={{id, msg} <- @streams.messages} id={id} class={"flex " <> (if msg.sender_id == @current_user.id, do: "justify-end", else: "justify-start")}>
                <div class={"max-w-md px-4 py-2 " <> (if msg.sender_id == @current_user.id, do: "msg-own", else: "msg-other")}>
                  <div :if={msg.sender_id != @current_user.id} class="text-xs font-semibold text-accent-dim mb-0.5">
                    <%= msg.sender.display_name || msg.sender.username %>
                  </div>
                  <div class="text-sm whitespace-pre-wrap"><%= msg.body %></div>
                  <div class={"text-xs mt-1 " <> (if msg.sender_id == @current_user.id, do: "text-black/60", else: "text-muted")}>
                    <%= format_time(msg.inserted_at) %>
                  </div>
                </div>
              </div>
            </div>
            <form phx-submit="send-message" class="chat-input p-4 flex gap-3 bg-secondary/50">
              <input type="text" name="body" value={@new_message} placeholder="type a message..."
                class="input-field flex-1" />
              <button type="submit" class="btn btn-primary rounded-xl px-6 py-2 text-sm">
                Send
              </button>
            </form>
          </div>
        </main>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("select-conversation", %{"id" => id}, socket) do
    messages = Conversations.list_messages(id)

    {:noreply,
     socket |> assign(current_conversation_id: id) |> stream(:messages, messages, reset: true)}
  end

  def handle_event("send-message", %{"body" => body}, socket) do
    body = String.trim(body)

    if body != "" and socket.assigns.current_conversation_id do
      {:ok, msg} =
        Conversations.send_message(
          socket.assigns.current_conversation_id,
          socket.assigns.current_user.id,
          body
        )

      for member <- Conversations.list_members(socket.assigns.current_conversation_id) do
        Phoenix.PubSub.broadcast(Sermo.PubSub, "user:#{member.user_id}", {:new_message, msg})
      end

      messages = Conversations.list_messages(socket.assigns.current_conversation_id)
      {:noreply, socket |> assign(new_message: "") |> stream(:messages, messages, reset: true)}
    else
      {:noreply, assign(socket, new_message: "")}
    end
  end

  def handle_event("new-conversation", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/conversations/new")}
  end

  def handle_info({:new_message, _message}, socket) do
    if socket.assigns.current_conversation_id do
      messages = Conversations.list_messages(socket.assigns.current_conversation_id)
      {:noreply, stream(socket, :messages, messages, reset: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:conversation_updated, _conversation_id}, socket) do
    refresh_conversations(socket)
  end

  defp refresh_conversations(socket) do
    conversations = Conversations.list_conversations(socket.assigns.current_user.id)
    enriched = enrich_conversations(conversations, socket.assigns.current_user.id)
    {:noreply, assign(socket, conversations: enriched)}
  end

  defp enrich_conversations(conversations, current_user_id) do
    Enum.map(conversations, fn conv ->
      display_name =
        if conv.type == "direct" do
          other = Enum.find(conv.members, fn m -> m.user_id != current_user_id end)
          if other, do: other.user.display_name || other.user.username, else: "Unknown"
        else
          conv.name || "Group"
        end

      %{conv | display_name: display_name}
    end)
  end

  defp format_time(nil), do: ""

  defp format_time(dt) do
    Calendar.strftime(dt, "%b %d %H:%M")
  end
end
