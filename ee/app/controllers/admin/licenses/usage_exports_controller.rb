# frozen_string_literal: true

module Admin
  module Licenses
    class UsageExportsController < Admin::ApplicationController
      include Admin::LicenseRequest

      before_action :require_license, only: :show

      feature_category :seat_cost_management
      urgency :low

      after_action :set_license_usage_data_exported, only: :show

      def show
        respond_to do |format|
          format.csv do
            csv_data = HistoricalUserData::CsvService.new(license.historical_data).generate

            send_data(csv_data, type: 'text/csv; charset=utf-8', filename: 'license_usage.csv')
          end
        end
      end

      private

      def set_license_usage_data_exported
        return unless ::License.current.offline_cloud_license?

        Gitlab::CurrentSettings.update(license_usage_data_exported: true)
      end
    end
  end
end
