class CleanupPodcastTable < ActiveRecord::Migration
  def up
    rename_table :podcasts_podcast, :podcasts
    change_table :podcasts do |t|
      t.column :source_type, :string
      
      t.rename :program_id, :source_id
      t.rename :link, :url
      
      t.change :slug, :string, null: true
      t.change :title, :string, null: true
      t.change :url, :string, null: true
      t.change :podcast_url, :string, null: true, default: nil
      t.change :itunes_url, :string, null: true, default: nil
      t.change :image_url, :string, null: true
      t.change :author, :string, null: true
      t.change :keywords, :string, null: true
      t.change :duration, :string, null: true
      t.change :item_type, :string, null: true
      t.change :source_type, :string, null: true
      t.change :description, :text, null: true
    end
  end

  def down
  end
end