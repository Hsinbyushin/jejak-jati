defmodule JejakJati.Reconciliation.WorkReconciler do
  @moduledoc """
  Reconciles bibliographic candidates originating from different sources.

  Unlike `WorkMatcher`, which compares a candidate against the user's original
  research query, the WorkReconciler compares source candidates with each
  other.

  Its purpose is to estimate whether two bibliographic records most likely
  describe the same underlying work.

  Reconciliation remains heuristic and explainable. A high score is evidence
  of equivalence, not absolute proof.
  """

  alias JejakJati.Research.SourceCandidate
  alias JejakJati.Bibliography.ISBN

  @type reason ::
          {:isbn_exact, non_neg_integer()}
          | {:title_exact, non_neg_integer()}
          | {:title_similarity, non_neg_integer()}
          | {:author_exact, non_neg_integer()}
          | {:author_similarity, non_neg_integer()}
          | {:publication_year_exact, non_neg_integer()}

  @type comparison :: %{
          left: SourceCandidate.t(),
          right: SourceCandidate.t(),
          score: non_neg_integer(),
          reasons: [reason()],
          decision: :same_work | :review | :different_work
        }

  @same_work_threshold 100
  @review_threshold 60

  @doc """
  Compares two bibliographic source candidates.
  """
  def compare(%SourceCandidate{} = left, %SourceCandidate{} = right) do
    reasons =
      []
      |> maybe_score_isbn(left.isbn, right.isbn)
      |> maybe_score_title(left.title, right.title)
      |> maybe_score_author(left.author_name, right.author_name)
      |> maybe_score_year(left.publication_year, right.publication_year)
      |> Enum.reverse()

    score =
      Enum.sum(
        Enum.map(reasons, fn {_reason, points} ->
          points
        end)
      )

    %{
      left: left,
      right: right,
      score: score,
      reasons: reasons,
      decision: classify(score)
    }
  end

  @doc """
  Compares candidates across source groups and returns all cross-source pairs.

  Candidates belonging to the same SourceRequest are deliberately not compared
  with one another here.
  """
  def reconcile(source_requests) when is_list(source_requests) do
    source_requests
    |> cross_source_pairs()
    |> Enum.map(fn {left, right} ->
      compare(left, right)
    end)
    |> Enum.sort_by(& &1.score, :desc)
  end

  @doc """
  Returns whether a reconciliation is relevant for continued research.

  Confirmed matches and ambiguous comparisons are preserved because they may
  contribute to evidence or require human review.

  Clearly different works are not persisted as research relationships.
  """
  def relevant?(%{decision: decision}) do
    decision in [:same_work, :review]
  end

  defp cross_source_pairs(source_requests) do
    source_requests
    |> Enum.with_index()
    |> Enum.flat_map(fn {left_request, index} ->
      source_requests
      |> Enum.drop(index + 1)
      |> Enum.flat_map(fn right_request ->
        for left <- left_request.source_candidates,
            right <- right_request.source_candidates do
          {left, right}
        end
      end)
    end)
  end

  defp maybe_score_isbn(reasons, nil, _right), do: reasons
  defp maybe_score_isbn(reasons, _left, nil), do: reasons

  defp maybe_score_isbn(reasons, left, right) do
    if ISBN.equivalent?(left, right) do
      [{:isbn_exact, 100} | reasons]
    else
      reasons
    end
  end

  defp maybe_score_title(reasons, nil, _right), do: reasons
  defp maybe_score_title(reasons, _left, nil), do: reasons

  defp maybe_score_title(reasons, left, right) do
    left = normalize_text(left)
    right = normalize_text(right)

    if left == right do
      [{:title_exact, 60} | reasons]
    else
      points =
        left
        |> token_similarity(right)
        |> Kernel.*(60)
        |> round()

      if points > 0 do
        [{:title_similarity, points} | reasons]
      else
        reasons
      end
    end
  end

  defp maybe_score_author(reasons, nil, _right), do: reasons
  defp maybe_score_author(reasons, _left, nil), do: reasons

  defp maybe_score_author(reasons, left, right) do
    left = normalize_text(left)
    right = normalize_text(right)

    if left == right do
      [{:author_exact, 40} | reasons]
    else
      points =
        left
        |> token_similarity(right)
        |> Kernel.*(40)
        |> round()

      if points > 0 do
        [{:author_similarity, points} | reasons]
      else
        reasons
      end
    end
  end

  defp maybe_score_year(reasons, nil, _right), do: reasons
  defp maybe_score_year(reasons, _left, nil), do: reasons

  defp maybe_score_year(reasons, left, right) do
    if String.trim(left) == String.trim(right) do
      [{:publication_year_exact, 10} | reasons]
    else
      reasons
    end
  end

  defp classify(score) when score >= @same_work_threshold,
    do: :same_work

  defp classify(score) when score >= @review_threshold,
    do: :review

  defp classify(_score),
    do: :different_work

  defp normalize_text(value) do
    value
    |> String.downcase()
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.replace(~r/[^\p{L}\p{N}\s]/u, " ")
    |> String.split(~r/\s+/u, trim: true)
    |> Enum.sort()
    |> Enum.join(" ")
  end

  defp token_similarity(left, right) do
    left_tokens =
      left
      |> String.split()
      |> MapSet.new()

    right_tokens =
      right
      |> String.split()
      |> MapSet.new()

    union =
      MapSet.union(left_tokens, right_tokens)

    if MapSet.size(union) == 0 do
      0.0
    else
      intersection =
        MapSet.intersection(left_tokens, right_tokens)

      MapSet.size(intersection) /
        MapSet.size(union)
    end
  end
end
