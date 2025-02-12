defmodule VyasaWeb.Router do
  use VyasaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug CORSPlug, origin: ["https://www.youtube.com/iframe_api"]
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

    live_session :gen_sangh_session,
      on_mount: [{VyasaWeb.Session, :sangh}, {VyasaWeb.Hook.UserAgent, :default}] do
      # NOTE: SLUG PATTERN:
      # /<mode>/<binding-info-slug>/<final_identifying_slug>?=<url-encoded-params>
      # TODO: to standardise, should rename "explore" -> "read"
      # TODO: @ks0m1c @rtshkmr the actions need to be udpated so that mediator can pipe things based on mode
      live "/explore/", ModeLive.Mediator, :show_sources
      live "/explore/:source_title/", ModeLive.Mediator, :show_chapters
      live "/explore/:source_title/:chap_no", ModeLive.Mediator, :show_verses
      # live "/discuss/", ModeLive.Mediator, :show_sources
      # live "/discuss/:source_title/", ModeLive.Mediator, :show_chapters
      # live "/discuss/:source_title/:chap_no", ModeLive.Mediator, :show_verses
    end

    live_admin "/admin" do
      admin_resource("/verses", VyasaWeb.Admin.Written.Verse)
      admin_resource("/events", VyasaWeb.Admin.Medium.Event)
    end
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
