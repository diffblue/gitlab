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
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects do
      helpers do
        params :push_rule_params do
          optional :deny_delete_tag, type: Boolean, desc: 'Deny deleting a tag', documentation: { example: true }
          optional :member_check, type: Boolean, desc: 'Restrict commits by author (email) to existing GitLab users', documentation: { example: true }
          optional :prevent_secrets, type: Boolean, desc: 'GitLab will reject any files that are likely to contain secrets', documentation: { example: true }
          optional :commit_message_regex, type: String, desc: 'All commit messages must match this', documentation: { example: 'Fixed \d+\..*' }
          optional :commit_message_negative_regex, type: String, desc: 'No commit message is allowed to match this', documentation: { example: 'ssh\:\/\/' }
          optional :branch_name_regex, type: String, desc: 'All branches names must match this', documentation: { example: '(feature|hotfix)\/*' }
          optional :author_email_regex, type: String, desc: 'All commit author emails must match this', documentation: { example: '@my-company.com$' }
          optional :file_name_regex, type: String, desc: 'All committed filenames must not match this', documentation: { example: '(jar|exe)$' }
          optional :max_file_size, type: Integer, desc: 'Maximum file size (MB)', documentation: { example: '1024' }
          optional :commit_committer_check,
            type: Boolean,
            desc: 'Users can only push commits to this repository if the committer email is one of their own verified emails.',
            documentation: { example: true }
          optional :reject_unsigned_commits, type: Boolean, desc: 'Reject commit when it’s not signed through GPG.', documentation: { example: true }
          at_least_one_of :deny_delete_tag, :member_check, :prevent_secrets,
            :commit_message_regex, :commit_message_negative_regex, :branch_name_regex, :author_email_regex,
            :file_name_regex, :max_file_size,
            :commit_committer_check,
            :reject_unsigned_commits
        end
      end

      desc 'Get project push rule' do
        success code: 200, model: EE::API::Entities::ProjectPushRule
        failure [{ code: 404, message: 'Not found' }]
        tags %w[projects push_rules]
      end
      get ":id/push_rule" do
        push_rule = user_project.push_rule
        present push_rule, with: EE::API::Entities::ProjectPushRule, user: current_user
      end

      desc 'Add a push rule to a project' do
        success code: 201, model: EE::API::Entities::ProjectPushRule
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[projects push_rules]
      end
      params do
        use :push_rule_params
      end
      post ":id/push_rule" do
        unprocessable_entity!('Project push rule exists') if user_project.push_rule
        create_or_update_push_rule
      end

      desc 'Update an existing project push rule' do
        success code: 200, model: EE::API::Entities::ProjectPushRule
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[projects push_rules]
      end
      params do
        use :push_rule_params
      end
      put ":id/push_rule" do
        not_found!('Push Rule') unless user_project.push_rule
        create_or_update_push_rule
      end

      desc 'Deletes project push rule' do
        success code: 204
        failure [{ code: 404, message: 'Not found' }]
        tags %w[projects push_rules]
      end
      delete ":id/push_rule" do
        push_rule = user_project.push_rule
        not_found!('Push Rule') unless push_rule

        push_rule.destroy

        no_content!
      end
    end
  end
end
