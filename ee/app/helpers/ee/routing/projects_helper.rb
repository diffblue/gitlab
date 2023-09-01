# frozen_string_literal: true
module EE
  module Routing
    module ProjectsHelper
      extend ::Gitlab::Utils::Override

      private

      override :use_work_items_path?
      def use_work_items_path?(issue)
        if issue.project&.okrs_mvc_feature_flag_enabled? && issue.licensed_feature_available?(:okrs)
          return super || issue.work_item_type.objective? || issue.work_item_type.key_result?
        end

        super
      end
    end
  end
end
