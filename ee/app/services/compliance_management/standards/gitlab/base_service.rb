# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class BaseService
        attr_reader :project

        STANDARD = :gitlab

        def initialize(project_id)
          @project = Project.find_by_id(project_id)
        end

        private

        def project_not_found
          ServiceResponse.error(message: "Project not found")
        end
      end
    end
  end
end
