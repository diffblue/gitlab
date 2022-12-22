# frozen_string_literal: true
module EE
  module Routing
    module ProjectsHelper
      extend ::Gitlab::Utils::Override

      private

      override :use_work_items_path?
      def use_work_items_path?(issue)
        super || (%w[objective
                     key_result].include?(issue.issue_type) && issue.project.okrs_mvc_feature_flag_enabled?)
      end
    end
  end
end
