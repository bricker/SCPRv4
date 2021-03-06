json.cache! [Api::Public::V3::VERSION, "v2", episode] do
  json.title    episode.title
  json.summary  episode.summary.to_s.html_safe

  json.air_date     episode.air_date
  json.public_url   episode.public_url

  json.assets do |asset|
    json.partial! api_view_path("assets", "collection"),
      assets: episode.assets
  end

  json.audio do
    json.partial! api_view_path("audio", "collection"),
      audio: episode.audio
  end

  json.program do
    json.partial! api_view_path("programs", "program"),
      program: episode.program
  end

  json.segments do
    json.partial! api_view_path("articles", "collection"),
      articles: episode.segments.map(&:to_article)
  end
end
