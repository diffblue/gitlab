# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class MergedReports
          include Gitlab::Ci::Reports::Security::Concerns::ScanFinding

          attr_reader :pipeline, :reports

          delegate :each, :empty?, to: :reports

          def initialize(pipeline, security_reports)
            @pipeline = pipeline
            @reports = prepare_reports(security_reports)
          end

          def findings
            @findings ||= reports.values.flatten.flat_map(&:findings).uniq
          end

          private

          def prepare_reports(security_reports)
            security_reports.each_with_object({}) do |reports, merged_reports|
              reports.each do |report_type, report|
                merged_reports[report_type] ||= []
                merged_reports[report_type] << report
              end
            end
          end
        end
      end
    end
  end
end
