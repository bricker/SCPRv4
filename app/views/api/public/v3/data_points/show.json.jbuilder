json.partial! api_view_path("shared", "version")

json.data_point do
  json.partial! api_view_path("data_points", "data_point"),
    data_point: @data_point
end
