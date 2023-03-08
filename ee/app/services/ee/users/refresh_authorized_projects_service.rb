# frozen_string_literal: true

module EE
  module Users
    module RefreshAuthorizedProjectsService
      extend ::Gitlab::Utils::Override

      override :update_authorizations
      # rubocop: disable Layout/LineLength
      # remove - The project IDs of the authorization rows to remove.
      # add - Rows to insert in the form `[{ user_id: user_id, project_id: project_id, access_level: access_level}, ...]`
      # rubocop: enable Layout/LineLength
      def update_authorizations(remove = [], add = [])
        user = super

        added_project_ids = add
                              .select { |auth| auth[:access_level] >= ::Member::DEVELOPER }
                              .pluck(:project_id) # rubocop: disable CodeReuse/ActiveRecord
                              .uniq

        project_ids = remove + added_project_ids

        ::Project.id_in(project_ids).each_batch do |projects|
          projects.each do |project|
            next unless project&.licensed_feature_available?(:security_orchestration_policies)

            project.all_security_orchestration_policy_configurations.each do |configuration|
              Security::ProcessScanResultPolicyWorker.perform_async(project.id, configuration.id)
            end
          end
        end

        user
      end
    end
  end
end
