# frozen_string_literal: true

module Admin
  module Licenses
    class UsageExportsController < Admin::ApplicationController
      include Admin::LicenseRequest

      before_action :require_license, only: :show

      feature_category :utilization
      urgency :low

      def show
        respond_to do |format|
          format.csv do
            csv_data = HistoricalUserData::CsvService.new(license.historical_data).generate

            send_data(csv_data, type: 'text/csv; charset=utf-8', filename: 'license_usage.csv')
          end
        end
      end
    end
  end
end
