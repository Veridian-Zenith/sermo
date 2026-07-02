defmodule SermoWeb.Router do
  use SermoWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug SermoWeb.Plugs.SecurityHeaders
    plug SermoWeb.UserAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SermoWeb do
    pipe_through :browser

    get "/", PageController, :index
    live "/login", LoginLive, :index
    live "/register", RegisterLive, :index
  end

  scope "/", SermoWeb do
    pipe_through [:browser, SermoWeb.Plugs.RateLimit]

    post "/session", SessionController, :create
    post "/register", RegistrationController, :create
  end

  scope "/", SermoWeb do
    pipe_through [:browser, SermoWeb.Plugs.RequireAuth]

    get "/logout", SessionController, :delete
    live "/chat", ChatLive, :index
    live "/conversations/new", NewConversationLive, :index
    live "/profile", ProfileLive, :index
  end

  scope "/api/v1", SermoWeb.API, as: :api do
    pipe_through :api

    post "/register", RegistrationController, :create
    post "/session", SessionController, :create
    delete "/session", SessionController, :delete
  end

  if Application.compile_env(:sermo, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: SermoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
