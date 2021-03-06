module Api::Public::V3
  class AlertsController < BaseController
    DEFAULTS = {
      :page  => 1,
      :limit => 5
    }

    MAX_RESULTS = 10

    before_filter \
      :set_hash_conditions,
      :sanitize_limit,
      :sanitize_page,
      :sanitize_type,
      only: [:index]

    before_filter :sanitize_id, only: [:show]


    def index
      @alerts = BreakingNewsAlert.published
        .where(@conditions).page(@page).per(@limit)

      respond_with @alerts
    end


    def show
      @alert = BreakingNewsAlert.published.where(id: @id).first

      if !@alert
        render_not_found and return false
      end

      respond_with @alert
    end


    private

    def sanitize_type
      if params[:type]
        @conditions[:alert_type] = params[:type].to_s
      end
    end
  end
end
