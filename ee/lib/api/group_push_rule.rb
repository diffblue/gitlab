# frozen_string_literal: true

module API
  class GroupPushRule < ::API::Base
    feature_category :source_code_management

    before { authenticate! }
    before { check_group_push_rule_access! }
    before { authorize_change_param(user_group, :commit_committer_check, :reject_unsigned_commits) }

    params do
      requires :id, type: String, desc: 'The ID or URL-encoded path of a group'
    end

    resource :groups do
      helpers do
        def check_group_push_rule_access!
          not_found! unless can?(current_user, :change_push_rules, user_group)
        end

        def create_or_update_push_rule
          service_response = PushRules::CreateOrUpdateService.new(
            container: user_group,
            current_user: current_user,
            params: declared_params(include_missing: false)
          ).execute

          push_rule = service_response.payload[:push_rule]

          if service_response.success?
            present(push_rule, with: EE::API::Entities::GroupPushRule, user: current_user)
          else
            render_validation_error!(push_rule)
          end
        end

        params :push_rule_params do
          optional :deny_delete_tag, type: Boolean, desc: 'Deny deleting a tag'
          optional :member_check, type: Boolean, desc: 'Restrict commits by author (email) to existing GitLab users'
          optional :prevent_secrets, type: Boolean, desc: 'GitLab will reject any files that are likely to contain secrets'
          optional :commit_message_regex, type: String, desc: 'All commit messages must match this', documentation: { example: 'Fixed \d+\..*' }
          optional :commit_message_negative_regex, type: String, desc: 'No commit message is allowed to match this', documentation: { example: 'ssh\:\/\/' }
          optional :branch_name_regex, type: String, desc: 'All branches names must match this', documentation: { example: '(feature|hotfix)\/*' }
          optional :author_email_regex, type: String, desc: 'All commit author emails must match this', documentation: { example: '@my-company.com$' }
          optional :file_name_regex, type: String, desc: 'All committed filenames must not match this', documentation: { example: '(jar|exe)$' }
          optional :max_file_size, type: Integer, desc: 'Maximum file size (MB)', documentation: { example: 20 }
          optional :commit_committer_check, type: Boolean, desc: 'Users may only push their own commits'
          optional :reject_unsigned_commits, type: Boolean, desc: 'Only GPG signed commits can be pushed to this repository'
          at_least_one_of :deny_delete_tag, :member_check, :prevent_secrets,
            :commit_message_regex, :commit_message_negative_regex, :branch_name_regex,
            :author_email_regex,
            :file_name_regex, :max_file_size,
            :commit_committer_check,
            :reject_unsigned_commits
        end
      end

      desc 'Get group push rule' do
        detail 'This feature was introduced in GitLab 13.4.'
        success code: 200, model: EE::API::Entities::GroupPushRule
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[push_rules]
      end
      get ":id/push_rule" do
        push_rule = user_group.push_rule

        not_found! unless push_rule

        present push_rule, with: EE::API::Entities::GroupPushRule, user: current_user
      end

      desc 'Add a push rule to a group' do
        detail 'This feature was introduced in GitLab 13.4.'
        success code: 201, model: EE::API::Entities::GroupPushRule
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[push_rules]
      end
      params do
        use :push_rule_params
      end
      post ":id/push_rule" do
        unprocessable_entity!('Group push rule exists, try updating') if user_group.push_rule
        create_or_update_push_rule
      end

      desc 'Edit push rule of a group' do
        detail 'This feature was introduced in GitLab 13.4.'
        success code: 200, model: EE::API::Entities::GroupPushRule
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[push_rules]
      end
      params do
        use :push_rule_params
      end
      put ":id/push_rule" do
        not_found!('Push Rule') unless user_group.push_rule
        create_or_update_push_rule
      end

      desc 'Deletes group push rule' do
        detail 'This feature was introduced in GitLab 13.4.'
        success code: 204
        failure [
          { code: 400, message: 'Validation error' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[push_rules]
      end
      delete ":id/push_rule" do
        push_rule = user_group.push_rule
        not_found! unless push_rule

        destroy_conditionally!(push_rule)
      end
    end
  end
end
