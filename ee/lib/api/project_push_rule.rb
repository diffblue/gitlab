# frozen_string_literal: true

module API
  class ProjectPushRule < ::API::Base
    feature_category :source_code_management
    before { authenticate! }
    before { authorize_admin_project }
    before { check_project_feature_available!(:push_rules) }
    before { authorize_change_param(user_project, :commit_committer_check, :reject_unsigned_commits) }

    helpers do
      def create_or_update_push_rule
        service_response = PushRules::CreateOrUpdateService.new(
          container: user_project,
          current_user: current_user,
          params: declared_params(include_missing: false)
        ).execute

        push_rule = service_response.payload[:push_rule]

        if service_response.success?
          present(push_rule, with: EE::API::Entities::ProjectPushRule, user: current_user)
        else
          render_validation_error!(push_rule)
        end
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      helpers do
        params :push_rule_params do
          optional :deny_delete_tag, type: Boolean, desc: 'Deny deleting a tag'
          optional :member_check, type: Boolean, desc: 'Restrict commits by author (email) to existing GitLab users'
          optional :prevent_secrets, type: Boolean, desc: 'GitLab will reject any files that are likely to contain secrets'
          optional :commit_message_regex, type: String, desc: 'All commit messages must match this'
          optional :commit_message_negative_regex, type: String, desc: 'No commit message is allowed to match this'
          optional :branch_name_regex, type: String, desc: 'All branches names must match this'
          optional :author_email_regex, type: String, desc: 'All commit author emails must match this'
          optional :file_name_regex, type: String, desc: 'All committed filenames must not match this'
          optional :max_file_size, type: Integer, desc: 'Maximum file size (MB)'
          optional :commit_committer_check, type: Boolean, desc: 'Users may only push their own commits'
          optional :reject_unsigned_commits, type: Boolean, desc: 'Only GPG signed commits can be pushed to this project'
          at_least_one_of :deny_delete_tag, :member_check, :prevent_secrets,
                          :commit_message_regex, :commit_message_negative_regex, :branch_name_regex, :author_email_regex,
                          :file_name_regex, :max_file_size,
                          :commit_committer_check,
                          :reject_unsigned_commits
        end
      end

      desc 'Get project push rule' do
        success EE::API::Entities::ProjectPushRule
      end
      get ":id/push_rule" do
        push_rule = user_project.push_rule
        present push_rule, with: EE::API::Entities::ProjectPushRule, user: current_user
      end

      desc 'Add a push rule to a project' do
        success EE::API::Entities::ProjectPushRule
      end
      params do
        use :push_rule_params
      end
      post ":id/push_rule" do
        unprocessable_entity!('Project push rule exists') if user_project.push_rule
        create_or_update_push_rule
      end

      desc 'Update an existing project push rule' do
        success EE::API::Entities::ProjectPushRule
      end
      params do
        use :push_rule_params
      end
      put ":id/push_rule" do
        not_found!('Push Rule') unless user_project.push_rule
        create_or_update_push_rule
      end

      desc 'Deletes project push rule'
      delete ":id/push_rule" do
        push_rule = user_project.push_rule
        not_found!('Push Rule') unless push_rule

        push_rule.destroy

        no_content!
      end
    end
  end
end
