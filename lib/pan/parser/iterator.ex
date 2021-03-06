defmodule Pan.Parser.Iterator do
  alias Pan.Parser.{Analyzer, Helpers}
  require Logger

# Actual feed parsing: Now the fun begins
  def parse(map, context \\ "tag", tags)

# We are done digging down
  def parse(map, _, []), do: map


  def parse(map, "episode_author", [head | tail]) do
    episode_author_map =
      if is_map(head) do
        Analyzer.call("episode_author", [head[:name], head[:attr], head[:value]])
      else
        %{name: String.slice(head, 0, 255)}
      end

    Helpers.deep_merge(map, %{author: episode_author_map})
    |> parse("episode_author", tail)
  end

  def parse(map, "image", [head | tail]) do
    image_map =  Analyzer.call(map, "image", [head[:name], head[:attr], head[:value]])

    Helpers.deep_merge(map, %{image: image_map})
    |> parse("image", tail)
  end


  def parse(map, "episode_image", [head | tail]) do
    episode_image_map =
      if is_map(head) do
        case Analyzer.call(map, "episode_image", [head[:name], head[:attr], head[:value]]) do
          {:error, "tag unknown"} ->
            raise "Tag unknown @ feed_url: " <> map[:feed][:self_link_url]
          map -> map
        end
      else
        %{image_url: head, image_title: head}
      end

    Helpers.deep_merge(map, episode_image_map)
    |> parse("episode_image", tail)
  end

  def parse(map, "chapter", [head | tail]) do
    chapter_map = Analyzer.call("chapter", [head[:name], head[:attr], head[:value]])

    Helpers.deep_merge(map, %{chapters: chapter_map})
    |> parse("chapter", tail)
  end


  def parse(map, context, [head | tail]) do
    if is_map(head) do
      podcast_map =
        case Analyzer.call(map, context, [head[:name], head[:attr], head[:value]]) do
          {:error, "tag unknown"} ->
            raise "Tag unknown @ feed_url: " <> map[:feed][:self_link_url]
          map -> map
        end

      Helpers.deep_merge(map, podcast_map)
      |> parse(context, tail)
    else
      parse(map, context, tail)
    end
  end

# We are done digging down
  def parse(map, _, [], _), do: map

  def parse(map, "contributor", [head | tail], guid) do
    contributor_map = Analyzer.call("contributor", [head[:name], head[:attr], head[:value]])

    Pan.Parser.Helpers.deep_merge(map, %{contributors: %{guid => contributor_map}})
    |> parse("contributor", tail, guid)
  end


  def parse(map, :podcast_contributor, _, []), do: map
  def parse(map, :podcast_contributor, role, [head | tail]) do
    contributor_map =
      if is_map(head) do
        Analyzer.call(role, [head[:name], head[:attr], head[:value]])
      else
        %{name: String.slice(head, 0, 255)}
      end

    Helpers.deep_merge(map, %{role => contributor_map})
    |> parse(:podcast_contributor, role, tail)
  end


  def parse(map, "episode", [head | tail], guid) do
    if is_map(head) do
      episode_map =
        case Analyzer.call(map, "episode", [head[:name], head[:attr], head[:value]]) do
          {:error, "tag unknown"} ->
            raise "Tag unknown @ feed_url: " <> map[:feed][:self_link_url]
          map -> map
        end

      Helpers.deep_merge(map, %{episodes: %{guid => episode_map}})
      |> parse("episode", tail, guid)
    else
      parse(map, "episode", tail, guid)
    end
  end


  def parse(map, "category", [head | tail], category_title) do
    if is_map(head) do
      category_map = Analyzer.call("category", [head[:name], head[:attr], head[:value]], category_title)

      Helpers.deep_merge(map, category_map)
      |> parse("category", tail, category_title)
    else
      map
    end
  end


  def parse(map, "episode-contributor", [head | tail], contributor_uuid) do
    contributor_map =
      Analyzer.call("episode-contributor", [head[:name], head[:attr], head[:value]])

    Helpers.deep_merge(map, %{contributors: %{contributor_uuid => contributor_map}})
    |> parse("episode-contributor", tail, contributor_uuid)
  end
end
