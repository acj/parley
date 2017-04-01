defmodule PhoenixShell.PageController do
  use PhoenixShell.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
