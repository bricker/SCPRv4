# This exists so that we can render this from another 
# controller without having to set @asset
json.array! assets do |asset|
  json.partial! api_view_path("assets", "asset"), asset: asset
end
