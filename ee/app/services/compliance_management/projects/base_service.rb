# frozen_string_literal: true

module ComplianceManagement
  module Projects
    class BaseService
      include BaseServiceUtility

      attr_reader :project, :user

      def initialize(project, user)
        @project = project
        @user = user
      end
    end
  end
end
