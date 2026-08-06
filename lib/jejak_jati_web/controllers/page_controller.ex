defmodule JejakJatiWeb.PageController do
  use JejakJatiWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
