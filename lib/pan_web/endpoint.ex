defmodule PanWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :pan

  socket "/socket", PanWeb.UserSocket,
    websocket: true, # or list of options
    longpoll: [check_origin: ["https://panoptikum.io", "https://ansible.local"]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  #
  # .well-known is for Let's Encrypt
  plug Plug.Static,
    at: "/", from: :pan, gzip: true,
    only: ~w(css fonts images img js favicon.ico robots.txt
             podlove-webplayer podlove-subscribe-button podigee-podcast-player
             .well-known opensearch.xml google0fe1c0bbe8862b06.html)

  plug Plug.Static,
    at: "thumbnails/", from: "/var/phoenix/pan-uploads/images/", gzip: true

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_pan_key",
    signing_salt: "sQ/BrqCz"

  plug PanWeb.Router
end
