defmodule JejakJatiWeb.PageControllerTest do
  use JejakJatiWeb.ConnCase

  test "GET / zeigt die Jejak-Jati-Startseite", %{conn: conn} do
    conn = get(conn, ~p"/")

    html = html_response(conn, 200)

    assert html =~ "Jejak Jati"
    assert html =~ "Evidenzbasierte Normdatenrecherche"
    assert html =~ "Recherche starten"
  end
end
