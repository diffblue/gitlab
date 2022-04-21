# frozen_string_literal: true

module AuditEvents
  module DateRange
    extend ActiveSupport::Concern

    DATE_RANGE_LIMIT = 31

    included do
      before_action :set_date_range, :validate_date_range, only: [:index]
    end

    private

    def set_date_range
      params[:created_before] = params[:created_before].blank? ? Date.current.end_of_day : Date.parse(params[:created_before]).end_of_day
      params[:created_after] = Date.current.beginning_of_month unless params[:created_after].present?
    end

    def validate_date_range
      return unless (params[:created_before].to_date - params[:created_after].to_date).days > DATE_RANGE_LIMIT.days

      message = _('Date range limited to %{number} days') % { number: DATE_RANGE_LIMIT }
      respond_to do |format|
        format.html do
          flash[:alert] = message
          render status: :bad_request
        end
        format.any { head :bad_request }
      end
    end
  end
end
