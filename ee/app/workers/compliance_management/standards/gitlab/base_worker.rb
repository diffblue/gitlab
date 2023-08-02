# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class BaseWorker
        include ApplicationWorker

        data_consistency :sticky
        idempotent!
        urgency :low

        feature_category :compliance_management

        # This worker expects the following keys passed inside the args hash:
        # 'project_id', 'user_id' (optional)
        def perform(args = {})
          project_id = args['project_id']
          user_id = args['user_id']
          project = Project.find_by_id(project_id)
          user = User.find_by_id(user_id)

          return unless project

          service_class.new(project: project, current_user: user).execute
        end
      end
    end
  end
end
