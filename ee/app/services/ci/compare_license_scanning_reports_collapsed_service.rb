# frozen_string_literal: true

module Ci
  class CompareLicenseScanningReportsCollapsedService < ::Ci::CompareLicenseScanningReportsService
    def serializer_class
      ::LicenseCompliance::CollapsedComparerSerializer
    end

    private

    attr_reader :comparer_entity

    def build_comparer(base_report, head_report)
      @comparer_entity = comparer_class.new(base_report, head_report)
    end

    def approval_required
      !!params.dig(:additional_params, :license_check) && has_denied_licenses?
    end

    def has_denied_licenses?
      licenses = comparer_entity.new_licenses

      return false if licenses.nil? || licenses.empty?

      licenses.any? do |l|
        'denied' == l.approval_status
      end
    end

    def serializer_params
      {
        project: project,
        current_user: current_user,
        approval_required: approval_required
      }
    end
  end
end
