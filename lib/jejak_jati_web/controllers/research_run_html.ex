defmodule JejakJatiWeb.ResearchRunHTML do
  use JejakJatiWeb, :html

  def status_label(:pending), do: "Ausstehend"
  def status_label(:running), do: "Läuft"
  def status_label(:review), do: "Prüfung erforderlich"
  def status_label(:completed), do: "Abgeschlossen"
  def status_label(:failed), do: "Fehlgeschlagen"

  embed_templates "research_run_html/*"
end
