# frozen_string_literal: true

module Dashboard
  module Environments
    class ListService
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def execute
        ::Dashboard::Projects::ListService
          .new(user, feature: :operations_dashboard)
          .execute(user.ops_dashboard_projects)
      end
    end
  end
end
