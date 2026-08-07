defmodule JejakJati.Bibliography.WorkMatcherTest do
  use ExUnit.Case, async: true

  alias JejakJati.Bibliography.WorkMatcher
  alias JejakJati.Sources.WorkResult

  test "gives an exact title and author match the maximum non-ISBN score" do
    candidate = %WorkResult{
      source: :dnb,
      source_id: "1",
      title: "In Search of Modernity",
      author_name: "Hadijah Rahmat"
    }

    match =
      WorkMatcher.score(candidate, %{
        title: "In Search of Modernity",
        author_name: "Hadijah Rahmat"
      })

    assert match.score == 100
    assert {:title_exact, 60} in match.reasons
    assert {:author_exact, 40} in match.reasons
  end

  test "matches inverted author names" do
    candidate = %WorkResult{
      source: :dnb,
      source_id: "1",
      title: "In Search of Modernity",
      author_name: "Rahmat, Hadijah"
    }

    match =
      WorkMatcher.score(candidate, %{
        title: "In Search of Modernity",
        author_name: "Hadijah Rahmat"
      })

    assert match.score == 100
  end

  test "gives an exact ISBN match a strong score" do
    candidate = %WorkResult{
      source: :dnb,
      source_id: "1",
      title: "Different title",
      isbn: "978-983-2085-01-0"
    }

    match =
      WorkMatcher.score(candidate, %{
        title: "In Search of Modernity",
        isbn: "9789832085010"
      })

    assert {:isbn_exact, 100} in match.reasons
    assert match.score >= 100
  end

  test "ranks a relevant candidate above unrelated candidates" do
    relevant = %WorkResult{
      source: :dnb,
      source_id: "relevant",
      title: "The Search for Modernity",
      author_name: "Rahmat, Hadijah"
    }

    unrelated = %WorkResult{
      source: :dnb,
      source_id: "unrelated",
      title: "Class, Individualization and Late Modernity",
      author_name: "Atkinson, W."
    }

    [first | _] =
      WorkMatcher.rank(
        [unrelated, relevant],
        %{
          title: "In Search of Modernity",
          author_name: "Hadijah Rahmat"
        }
      )

    assert first.result.source_id == "relevant"
  end

  test "classifies a strong match" do
    matches = [%{score: 95}]
    assert WorkMatcher.classify(matches) == :strong_match
  end

  test "classifies an uncertain match for review" do
    matches = [%{score: 65}]
    assert WorkMatcher.classify(matches) == :review
  end

  test "rejects weak matches" do
    matches = [%{score: 14}]
    assert WorkMatcher.classify(matches) == :no_match
  end
end
