defmodule Pan.Parser do
  use Pan.Web, :controller
  alias Pan.Feed
  alias Pan.Podcast
  alias Pan.User
  alias Pan.Episode
  alias Pan.AlternateFeed
  alias Pan.Contributor
  alias Pan.Category
  alias Pan.Chapter
  alias Pan.Enclosure
  alias Pan.Repo
  alias Pan.Parser.PC
  alias Pan.Parser.EP
  alias Pan.Parser.FD
  import SweetXml

  def import_feed(url) do
    %HTTPoison.Response{body: xml} = HTTPoison.get!(url, [], [follow_redirect: true,
                                                              connect_timeout: 20000,
                                                              recv_timeout: 20000,
                                                              timeout: 20000])

    {:ok, next_page_url} = update_from_feed(xml, url)

    if next_page_url != "" do
      import_feed(next_page_url)
    end
  end

  def update_from_feed(xml, url) do
    {:ok, xml_feed} = FD.parse(xml, url)

    {:ok, feed} = find_or_create_feed(xml, xml_feed, url)

    {:ok, episodes} = EP.parse(xml)
    find_or_create_episodes(episodes, feed.podcast_id)

    {:ok, feed.next_page_url}
  end


  def find_or_create_feed(xml, xml_feed, url) do
    case Repo.get_by(Feed, self_link_url: xml_feed.self_link_url) do
      nil ->
        find_or_create_podcast(xml, url)
      feed ->
        {:ok, feed}
    end
  end


  def find_or_create_podcast(xml, url) do
#    {:ok, owner} = find_or_create_owner(xml)

    # {:ok, podcast} = PC.parse(xml)

    # {:ok, podcast} =
    #   case Repo.get_by(Podcast, title: podcast.title) do
    #     nil ->
    #       Repo.insert(%{podcast | owner_id: owner.id})
    #     podcast ->
    #       {:ok, podcast}
    #   end

    # {:ok, feed} = FD.parse(xml, url)
    # Repo.insert(%{feed | podcast_id: podcast.id})
  end


   def create_contributors(xml, podcast, contributors) do
     for contributor <- contributors do
       if Repo.get_by(Contributor, uri: contributor.uri) == nil do
         associate(contributor, podcast)
       end
     end
   end


  def associate(instance, podcast) do
    category = Repo.preload(instance, :podcasts)

    category
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:podcasts, [podcast | category.podcasts])
    |> Repo.update!
  end


  def find_or_create_episodes(episodes, podcast_id) do
    for xml_episode <- episodes do
      unless Repo.get_by(Episode, guid: xml_episode.guid, link: xml_episode.link) do
        {:ok, episode} = create_episode(xml_episode, podcast_id)

        for chapter <- xml_episode.chapters do
          create_chapter(chapter, episode.id)
        end

        for enclosure <- xml_episode.enclosures do
          create_enclosure(enclosure, episode.id)
         end
      end
    end
  end

  def create_contributor(contributor) do
    Repo.insert(
      %Contributor{name: contributor.name,
                   uri:  contributor.uri})
  end

  def find_or_create_episode_contributor(contributor, episode) do
    if (Repo.get_by(Contributor, uri: contributor.uri) == nil) do
      {:ok, contributor} = create_contributor(contributor)

      contributor
      |> Repo.preload(:episodes)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:episodes, [episode])
      |> Repo.update!
    end
  end


  def create_enclosure(enclosure, episode_id) do
    Repo.insert(
      %Enclosure{url:        enclosure.url,
               length:     enclosure.length,
               type:       enclosure.type,
               guid:       enclosure.guid,
               episode_id: episode_id})
  end


  def create_chapter(chapter, episode_id) do
    Repo.insert(
      %Chapter{start:      chapter.start,
               title:      String.slice(chapter.title, 0, 255),
               episode_id: episode_id})
  end


  def create_episode(episode, podcast_id) do
    guid =
      if episode.guid == "" do
        episode.link
      else
        episode.guid
      end

    Repo.insert(
      %Episode{title:              episode.title,
               link:               episode.link,
               publishing_date:    episode.publishing_date,
               guid:               guid,
               description:        episode.description,
               shownotes:          episode.shownotes,
               payment_link_title: episode.payment_link.title,
               payment_link_url:   String.slice(episode.payment_link.url, 0, 255),
               deep_link:          episode.deep_link,
               duration:           episode.duration,
               author:             episode.author,
               subtitle:           episode.subtitle,
               summary:            episode.summary,
               podcast_id:         podcast_id})
  end
end