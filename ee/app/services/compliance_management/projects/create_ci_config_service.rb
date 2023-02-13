# frozen_string_literal: true
module ComplianceManagement
  module Projects
    class CreateCiConfigService < ComplianceManagement::Projects::BaseService
      DEFAULT_TEMPLATE = "Getting-Started"

      def execute
        return error(_("Project must have default branch"), 422) if project.default_branch.nil?
        return error(_("Ci config already present"), 422) if project.ci_config_for(project.default_branch)

        create_merge_request
      end

      private

      def create_merge_request
        commit_params = generate_commit_params
        branch_name = commit_params[:branch_name]

        create_branch_response = ::Branches::CreateService.new(project, user)
                                                          .execute(branch_name,
                                                            project.default_branch)

        if create_branch_response[:status] == :error
          create_branch_response[:http_status] = 400
          return create_branch_response
        end

        create_commit_response = ::Files::CreateService.new(project, user, commit_params).execute

        if create_commit_response[:status] == :error
          create_commit_response[:http_status] = 400
          return create_commit_response
        end

        merge_request = ::MergeRequests::CreateService.new(project: project,
          current_user: user,
          params: mr_params(project, branch_name)).execute

        return error(merge_request.errors.full_messages.to_sentence, 422) unless merge_request.valid?

        success({ merge_request: merge_request })
      end

      def mr_params(project, source_branch)
        {
          title: 'Add ci config file',
          target_branch: project.default_branch,
          source_branch: source_branch
        }
      end

      def generate_commit_params
        branch_name = "add-ci-config-#{SecureRandom.hex(8)}"
        {
          commit_message: 'Add ci config file',
          file_path: project.ci_config_path_or_default,
          file_content: file_content,
          branch_name: branch_name,
          start_branch: branch_name
        }
      end

      def file_content
        template = Gitlab::Template::GitlabCiYmlTemplate.find(DEFAULT_TEMPLATE)
        template.present? ? template.content : ''
      end
    end
  end
end
