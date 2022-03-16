# frozen_string_literal: true

module EE
  module AlertManagement
    module CreateAlertIssueService
      extend ::Gitlab::Utils::Override

      override :perform_after_create_tasks
      def perform_after_create_tasks(issue)
        super
        copy_metric_images_to(issue)
      end

      private

      def copy_metric_images_to(issue)
        alert.metric_images.find_each do |img|
          ::IncidentManagement::Incidents::UploadMetricService
            .new(issue, user, { file: img.file, url: img.url, url_text: img.url_text })
            .execute
        end
      end
    end
  end
end
