defmodule JejakJatiWeb.ResearchRunHTML do
  use JejakJatiWeb, :html

  def status_label(:pending), do: "Ausstehend"
  def status_label(:running), do: "Läuft"
  def status_label(:review), do: "Prüfung erforderlich"
  def status_label(:completed), do: "Abgeschlossen"
  def status_label(:failed), do: "Fehlgeschlagen"
  def source_label(:dnb), do: "Deutsche Nationalbibliothek"
  def source_label(:open_library), do: "Open Library"

  def source_status_label(:pending), do: "Ausstehend"
  def source_status_label(:running), do: "Läuft"
  def source_status_label(:succeeded), do: "Erfolgreich"
  def source_status_label(:failed), do: "Fehlgeschlagen"

  def decision_label(:strong_match), do: "Starker Treffer"
  def decision_label(:review), do: "Manuelle Prüfung"
  def decision_label(:no_match), do: "Kein belastbarer Treffer"
  def decision_label(nil), do: "Noch keine Bewertung"

  def match_reason_label("isbn_exact"), do: "ISBN exakt"
  def match_reason_label("title_exact"), do: "Titel exakt"
  def match_reason_label("title_similarity"), do: "Titelähnlichkeit"
  def match_reason_label("author_exact"), do: "Autor exakt"
  def match_reason_label("author_similarity"), do: "Autorenähnlichkeit"

  def match_reason_label(reason), do: reason
  embed_templates "research_run_html/*"

  def reconciliation_decision_label(:same_work), do: "Wahrscheinlich dasselbe Werk"
  def reconciliation_decision_label(:review), do: "Manuelle Prüfung erforderlich"
  def reconciliation_decision_label(:different_work), do: "Unterschiedliche Werke"

  def reconciliation_reason_label("isbn_exact"),
    do: "ISBN identisch"

  def reconciliation_reason_label("title_exact"), do: "Titel identisch"
  def reconciliation_reason_label("title_similarity"), do: "Titelähnlichkeit"
  def reconciliation_reason_label("author_exact"), do: "Autor identisch"
  def reconciliation_reason_label("author_similarity"), do: "Autorenähnlichkeit"
  def reconciliation_reason_label("publication_year_exact"), do: "Erscheinungsjahr identisch"
  def reconciliation_reason_label(reason), do: reason
end
