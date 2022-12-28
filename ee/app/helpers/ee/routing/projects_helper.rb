# frozen_string_literal: true
module EE
  module Routing
    module ProjectsHelper
      extend ::Gitlab::Utils::Override

      private

      override :use_work_items_path?
      def use_work_items_path?(issue)
        if issue.project.okrs_mvc_feature_flag_enabled? && issue.project.licensed_feature_available?(:okrs)
          return super || issue.objective? || issue.key_result?
        end

        super
      end
    end
  end
end
