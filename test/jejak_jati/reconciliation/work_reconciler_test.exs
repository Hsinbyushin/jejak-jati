defmodule JejakJati.Reconciliation.WorkReconcilerTest do
  use ExUnit.Case, async: true

  alias JejakJati.Reconciliation.WorkReconciler
  alias JejakJati.Research.SourceCandidate
  alias JejakJati.Research.SourceRequest

  test "recognizes matching works from different sources" do
    dnb = %SourceCandidate{
      source_id: "123456789",
      title: "In Search of Modernity",
      author_name: "Rahmat, Hadijah",
      isbn: "9789832085010",
      publication_year: "2001",
      score: 200
    }

    open_library = %SourceCandidate{
      source_id: "OL123456W",
      title: "In Search of Modernity",
      author_name: "Hadijah Rahmat",
      isbn: "978-983-2085-01-0",
      publication_year: "2001",
      score: 200
    }

    result =
      WorkReconciler.compare(dnb, open_library)

    assert result.decision == :same_work
    assert result.score == 210

    assert {:isbn_exact, 100} in result.reasons
    assert {:title_exact, 60} in result.reasons
    assert {:author_exact, 40} in result.reasons
    assert {:publication_year_exact, 10} in result.reasons
  end

  test "rejects clearly unrelated works" do
    left = %SourceCandidate{
      source_id: "1",
      title: "In Search of Modernity",
      author_name: "Hadijah Rahmat",
      publication_year: "2001",
      score: 100
    }

    right = %SourceCandidate{
      source_id: "2",
      title: "The Economic Transformation of Zambia",
      author_name: "Stephen Chan",
      publication_year: "2025",
      score: 10
    }

    result =
      WorkReconciler.compare(left, right)

    assert result.decision == :different_work
    assert result.score < 60
  end

  test "reconciles candidates across source requests" do
    dnb_candidate = %SourceCandidate{
      source_id: "dnb-1",
      title: "In Search of Modernity",
      author_name: "Rahmat, Hadijah",
      isbn: "9789832085010",
      publication_year: "2001",
      score: 200
    }

    open_library_candidate = %SourceCandidate{
      source_id: "ol-1",
      title: "In Search of Modernity",
      author_name: "Hadijah Rahmat",
      isbn: "9789832085010",
      publication_year: "2001",
      score: 200
    }

    dnb_request = %SourceRequest{
      source: :dnb,
      source_candidates: [dnb_candidate]
    }

    open_library_request = %SourceRequest{
      source: :open_library,
      source_candidates: [open_library_candidate]
    }

    [comparison] =
      WorkReconciler.reconcile([
        dnb_request,
        open_library_request
      ])

    assert comparison.decision == :same_work
  end

  test "considers same-work and review comparisons relevant" do
    assert WorkReconciler.relevant?(%{decision: :same_work})
    assert WorkReconciler.relevant?(%{decision: :review})
  end

  test "does not consider different works relevant" do
    refute WorkReconciler.relevant?(%{decision: :different_work})
  end
end
