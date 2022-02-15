# frozen_string_literal: true

module AuditEvents
  module EnforcesValidDateParams
    extend ActiveSupport::Concern

    included do
      before_action :validate_date_params, only: [:index]
    end

    private

    def validate_date_params
      unless valid_utc_date?(params[:created_before]) && valid_utc_date?(params[:created_after])
        respond_to do |format|
          format.html do
            flash[:alert] = _('Invalid date format. Please use UTC format as YYYY-MM-DD')
            render status: :bad_request
          end
          format.any { head :bad_request }
        end
      end
    end

    def valid_utc_date?(date)
      return true if date.blank?

      return false unless date =~ Gitlab::Regex.utc_date_regex

      return true if Date.parse(date)
    rescue Date::Error
      false
    end
  end
end
