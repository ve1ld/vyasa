defmodule VyasaWeb.Router do
  use VyasaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VyasaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end



  scope "/", VyasaWeb do
    pipe_through :browser


    get "/og/:filename", OgImageController, :show

    get "/", PageController, :home
    live "/gita/", GitaLive.Index, :index
    live "/gita/:chapter_id", GitaLive.Show, :show
    live "/gita/:chapter_id/:verse_id", GitaLive.ShowVerse, :show_verse
    live "/texts", TextLive.Index, :index
    live "/texts/new", TextLive.Index, :new
    live "/texts/:id/edit", TextLive.Index, :edit

    live "/texts/:id", TextLive.Show, :show
    live "/texts/:id/show/edit", TextLive.Show, :edit

  end

  # Other scopes may use custom stacks.
  # scope "/api", VyasaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:vyasa, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser


      live_dashboard "/dashboard", metrics: VyasaWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
