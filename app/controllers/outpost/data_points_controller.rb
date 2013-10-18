class Outpost::DataPointsController < Outpost::ResourceController
  outpost_controller

  define_list do |l|
    l.default_order_attribute   = "group_name"
    l.default_order_direction   = ASCENDING
    l.per_page                  = 200

    l.column :group_name, header: "Group"
    l.column :title
    l.column :data_key,
      :header                     => "Key",
      :sortable                   => true,
      :default_order_direction    => ASCENDING

    l.column :data_value,
      :header       => "Value",
      :quick_edit   => true

    l.column :notes
    l.column :updated_at,
      :header                     => "Last Updated",
      :sortable                   => true,
      :default_order_direction    => DESCENDING

    l.filter :group_name,
      :collection => -> { DataPoint.group_names_select_collection }
  end
end
