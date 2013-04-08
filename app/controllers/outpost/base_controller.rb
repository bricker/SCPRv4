class Outpost::BaseController < Outpost::ApplicationController
  before_filter :setup_tickets
  before_filter :set_current_homepage
  before_filter :add_params_for_newrelic

  #------------------------
  # We need a new Ticket on every page, since we're offering
  # the ability to submit a ticket from any page in the CMS
  def setup_tickets
    @ticket  = Ticket.new
    @tickets = Ticket.opened
  end

  #------------------------
  # Grab the most recent homepage for the Quicknav
  def set_current_homepage
    @current_homepage = Homepage.published.first
  end

  #-------------------------

  def add_params_for_newrelic
    if current_user
      NewRelic::Agent.add_custom_parameters(
        :current_user_id   => current_user.id, 
        :current_user_name => current_user.name
      )
    end
  end

  #-------------------------
  # Override this method from CustomErrors so we can specify the template path
  def render_error(status, e=StandardError)
    if Rails.application.config.consider_all_requests_local
      raise e
    else
      render template: "/outpost/errors/error_#{status}", status: status, locals: { error: e }
      report_error(e)
    end
  end
  
  #-------------------------

  def with_rollback(object)
    object.transaction do
      yield if block_given?
      raise ActiveRecord::Rollback
    end
  end
end
