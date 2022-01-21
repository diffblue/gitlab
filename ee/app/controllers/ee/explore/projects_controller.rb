# frozen_string_literal: true

module EE
  module Explore
    module ProjectsController
      extend ::Gitlab::Utils::Override

      private

      override :preload_associations
      def preload_associations(projects)
        super.with_compliance_framework_settings
      end
    end
  end
end
