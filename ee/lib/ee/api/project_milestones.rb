# frozen_string_literal: true

module EE
  module API
    module ProjectMilestones
      extend ActiveSupport::Concern

      prepended do
        include EE::API::MilestoneResponses # rubocop: disable Cop/InjectEnterpriseEditionModule

        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end
        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Get a list of burndown events' do
            detail 'This feature was introduced in GitLab 12.1.'
          end
          get ':id/milestones/:milestone_id/burndown_events' do
            authorize! :read_milestone, user_project

            milestone_burndown_events_for(user_project)
          end
        end
      end
    end
  end
end
