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
    end
  end
end
