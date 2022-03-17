# frozen_string_literal: true

module Projects
  module Security
    class CorpusManagementController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action do
        authorize_read_coverage_fuzzing!
      end

      feature_category :fuzz_testing

      def show
      end
    end
  end
end
