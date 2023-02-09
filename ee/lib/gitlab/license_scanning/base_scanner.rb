# frozen_string_literal: true

module Gitlab
  module LicenseScanning
    class BaseScanner
      attr_reader :project, :pipeline

      def initialize(project, pipeline)
        @project = project
        @pipeline = pipeline
      end

      def self.latest_pipeline(project, ref)
        raise "Must implement method in child class"
      end

      def report
        raise "Must implement method in child class"
      end

      def has_data?
        raise "Must implement method in child class"
      end

      def results_available?
        raise "Must implement method in child class"
      end

      def latest_build_for_default_branch
        raise "Must implement method in child class"
      end

      private

      def empty_report
        ::Gitlab::Ci::Reports::LicenseScanning::Report.new
      end
    end
  end
end
