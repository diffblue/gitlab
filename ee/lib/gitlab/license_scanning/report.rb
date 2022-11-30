# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class Report
      attr_reader :project, :pipeline

      def initialize(project, pipeline = nil)
        @project = project
        @pipeline = pipeline
      end

      def license_scanning_report
        pipeline.blank? ? empty_report : pipeline.license_scanning_report
      end

      private

      def empty_report
        ::Gitlab::Ci::Reports::LicenseScanning::Report.new
      end
    end
  end
end
