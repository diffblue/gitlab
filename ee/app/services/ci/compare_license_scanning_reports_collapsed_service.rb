# frozen_string_literal: true

module Ci
  class CompareLicenseScanningReportsCollapsedService < ::Ci::CompareLicenseScanningReportsService
    include ::Gitlab::Utils::StrongMemoize

    def serializer_class
      ::LicenseCompliance::CollapsedComparerSerializer
    end

    private

    attr_reader :comparer_entity

    def build_comparer(base_report, head_report)
      @comparer_entity = comparer_class.new(base_report, head_report)
    end

    def approval_required
      merge_request = project.merge_requests.find(params[:id])

      return false unless merge_request

      (merge_request.approval_rules.license_compliance.any? ||
        merge_request.approval_rules.scan_finding.any?) && has_denied_licenses?
    end

    def has_denied_licenses?
      strong_memoize(:has_denied_licenses) do
        licenses = comparer_entity.new_licenses

        next false if licenses.nil? || licenses.empty?

        licenses.any? do |l|
          'denied' == l.approval_status
        end
      end
    end

    def serializer_params
      {
        project: project,
        current_user: current_user,
        approval_required: approval_required,
        has_denied_licenses: has_denied_licenses?
      }
    end
  end
end
