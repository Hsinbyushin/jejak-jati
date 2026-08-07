defmodule JejakJati.Bibliography.WorkMatcher do
  @moduledoc """
  Ranks bibliographic source results against the work supplied by the user.

  Source adapters such as the DNB adapter are responsible for discovering
  candidate records. The WorkMatcher is responsible for estimating how well
  those candidates correspond to the work Jejak Jati is researching.

  Matching is deliberately kept separate from source retrieval. This allows
  the same matching logic to be reused for results from DNB, Wikidata,
  Open Library, Crossref, or future sources.

  A score is not proof of identity. It is a heuristic used to order candidates
  and to make the reasons for that ordering explicit.
  """

  alias JejakJati.Sources.WorkResult

  @type reason ::
          {:isbn_exact, non_neg_integer()}
          | {:title_exact, non_neg_integer()}
          | {:title_similarity, non_neg_integer()}
          | {:author_exact, non_neg_integer()}
          | {:author_similarity, non_neg_integer()}

  @type match :: %{
          result: WorkResult.t(),
          score: non_neg_integer(),
          reasons: [reason()]
        }

  @doc """
  Scores and ranks a list of bibliographic candidates.

  The highest-scoring candidate is returned first.
  """
  def rank(candidates, query) when is_list(candidates) do
    candidates
    |> Enum.map(&score(&1, query))
    |> Enum.sort_by(& &1.score, :desc)
  end

  @doc """
  Scores a single bibliographic candidate against the original query.
  """
  def score(%WorkResult{} = result, query) do
    reasons =
      []
      |> maybe_score_isbn(result.isbn, query[:isbn])
      |> maybe_score_title(result.title, query[:title])
      |> maybe_score_author(result.author_name, query[:author_name])

    %{
      result: result,
      score: Enum.sum(Enum.map(reasons, fn {_reason, points} -> points end)),
      reasons: Enum.reverse(reasons)
    }
  end

  # An exact ISBN match is extremely strong bibliographic evidence and
  # therefore receives the highest individual weight.
  defp maybe_score_isbn(reasons, nil, _query_isbn), do: reasons
  defp maybe_score_isbn(reasons, _candidate_isbn, nil), do: reasons

  defp maybe_score_isbn(reasons, candidate_isbn, query_isbn) do
    if normalize_isbn(candidate_isbn) == normalize_isbn(query_isbn) do
      [{:isbn_exact, 100} | reasons]
    else
      reasons
    end
  end

  # Titles are compared twice:
  #
  #   * an exact normalized match receives a strong score;
  #   * otherwise we calculate token overlap for partial matches.
  #
  # This is intentionally transparent rather than mathematically elaborate.
  # We can replace the heuristic later without changing source adapters.
  defp maybe_score_title(reasons, nil, _query_title), do: reasons
  defp maybe_score_title(reasons, _candidate_title, nil), do: reasons

  defp maybe_score_title(reasons, candidate_title, query_title) do
    candidate = normalize_text(candidate_title)
    query = normalize_text(query_title)

    if candidate == query do
      [{:title_exact, 60} | reasons]
    else
      similarity = token_similarity(candidate, query)
      points = round(similarity * 60)

      if points > 0 do
        [{:title_similarity, points} | reasons]
      else
        reasons
      end
    end
  end

  # Author names receive fewer points than titles because names can appear in
  # different cataloguing forms, for example:
  #
  #     Hadijah Rahmat
  #     Rahmat, Hadijah
  #
  # Normalization and token comparison allow both forms to match without
  # requiring source-specific knowledge in this module.
  defp maybe_score_author(reasons, nil, _query_author), do: reasons
  defp maybe_score_author(reasons, _candidate_author, nil), do: reasons

  defp maybe_score_author(reasons, candidate_author, query_author) do
    candidate = normalize_text(candidate_author)
    query = normalize_text(query_author)

    if candidate == query do
      [{:author_exact, 40} | reasons]
    else
      similarity = token_similarity(candidate, query)
      points = round(similarity * 40)

      if points > 0 do
        [{:author_similarity, points} | reasons]
      else
        reasons
      end
    end
  end

  # Normalize text before comparison so that capitalization and punctuation
  # don't influence matching unnecessarily.
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

  defp normalize_isbn(value) do
    value
    |> String.replace(~r/[^0-9Xx]/u, "")
    |> String.upcase()
  end

  # Jaccard similarity gives us a simple and explainable measure of how many
  # normalized words two strings have in common.
  #
  # A result of:
  #
  #     1.0 = identical token sets
  #     0.0 = no shared tokens
  #
  # Intermediate values represent partial overlap.
  defp token_similarity(left, right) do
    left_tokens = left |> String.split() |> MapSet.new()
    right_tokens = right |> String.split() |> MapSet.new()

    union = MapSet.union(left_tokens, right_tokens)

    if MapSet.size(union) == 0 do
      0.0
    else
      intersection = MapSet.intersection(left_tokens, right_tokens)

      MapSet.size(intersection) / MapSet.size(union)
    end
  end

  @strong_match_threshold 80
  @review_threshold 50

  @doc """
  Classifies the ranked candidate list according to its best score.

  The classification describes confidence in the best bibliographic candidate,
  not the identity of the person.
  """
  def classify(matches) when is_list(matches) do
    case matches do
      [] ->
        :no_match

      [%{score: score} | _] when score >= @strong_match_threshold ->
        :strong_match

      [%{score: score} | _] when score >= @review_threshold ->
        :review

      _ ->
        :no_match
    end
  end
end
