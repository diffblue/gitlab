# frozen_string_literal: true

module IncidentManagement
  module Incidents
    class UploadMetricService < BaseService
      def initialize(issuable, current_user, params = {})
        super

        @issuable = issuable
        @project = issuable&.project
        @file = params.fetch(:file)
        @url = params.fetch(:url, nil)
        @url_text = params.fetch(:url_text, nil)
      end

      def execute
        return ServiceResponse.error(message: "Not allowed!") unless issuable.metric_images_available? && can_upload_metrics?

        upload_metric

        ServiceResponse.success(payload: { metric: metric, issuable: issuable })
      rescue ::ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message)
      end

      attr_reader :issuable, :project, :file, :url, :url_text, :metric

      private

      def upload_metric
        @metric = IssuableMetricImage.create!(
          issue: issuable,
          file: file,
          url: url,
          url_text: url_text
        )
      end

      def can_upload_metrics?
        current_user&.can?(:upload_issuable_metric_image, issuable)
      end
    end
  end
end
