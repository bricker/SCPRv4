class Admin::NewsStoriesController < Admin::ResourceController
  def preview
    @story = ContentBase.obj_by_key!(params[:obj_key])
    @story.assign_attributes(params[:news_story])
    @title = @story.to_title
    
    render "/news/_story", layout: "/admin/preview", locals: { story: @story }
  end
end
