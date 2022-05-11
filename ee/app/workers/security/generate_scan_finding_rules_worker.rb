# frozen_string_literal: true

module Security
  class GenerateScanFindingRulesWorker
    include ApplicationWorker

    MERGE_REQUEST_TITLE = "Auto-generated Vulnerability Check Migration"

    MERGE_REQUEST_DESCRIPTION = <<~NODES
      In GitLab 15.0, the Vulnerability Check capability has been removed and replaced with Scan Result policies. This merge request was auto-generated with the Vulnerability Check settings that existed prior to their removal. To maintain the same security approval rules that you had in place prior to GitLab 15.0, we recommend that you merge this new Scan Result policy.

      To learn more about this change, see the following links:

      - [Brief video overview](https://youtu.be/w5I9gcUgr9U) of Scan Result policies.
      - Documentation on [Security and compliance policies](https://docs.gitlab.com/ee/user/application_security/policies/).
      - Documentation on [Scan Result policies](https://docs.gitlab.com/ee/user/application_security/policies/scan-result-policies.html).
      - [Deprecation notice](https://docs.gitlab.com/ee/update/deprecations.html#vulnerability-check) for the vulnerability check feature.
    NODES

    POLICY_NAME = "Vulnerability Check"
    POLICY_DESCRIPTION =
      "This security approval policy was auto-generated based on the previous vulnerability check rule."

    data_consistency :always

    sidekiq_options retry: true

    idempotent!

    feature_category :security_orchestration

    attr_reader :project, :approval_rule, :access_token

    def perform(approval_rule_id)
      @approval_rule = ApprovalProjectRule.find_by_id(approval_rule_id)

      return unless approval_rule&.vulnerability?

      @project = approval_rule.project

      # Projects on a user namespace are not supported
      if project.namespace.is_a?(Namespaces::UserNamespace)
        raise 'UserNamespace is not supported'
      end

      # Considering only Ultimate/Gold licenses
      unless project.licensed_feature_available?(:security_orchestration_policies)
        raise 'security_orchestration_policies not available for this license'
      end

      # resource token is created on the scope of the project namespace
      token_response = ::ResourceAccessTokens::CreateService.new(
        User.migration_bot,
        project.namespace,
        { name: "migration helper", scopes: ["write_repository"] }
      ).execute

      if token_response[:status] != :success
        raise "Failed to create access token: #{token_response}"
      end

      # from here onwards the code would be similar to the worker as described in this MR.
      @access_token = token_response.payload[:access_token]

      update_security_project
    rescue StandardError => e
      # Delete Vulnerability-Check rule
      approval_rule.delete

      Gitlab::AppLogger.warn(
        "Failed to create scan result policy for approval_rule_id: #{approval_rule_id} with #{e.message}"
      )
    ensure
      revoke_access_token
    end

    private

    # Convert rule into policy yaml/hash
    # rubocop: disable CodeReuse/ActiveRecord
    def policy_commit_params(policy_name, override_branch_name)
      rules = [{
        type: 'scan_finding',
        branches: approval_rule.protected_branches,
        scanners: approval_rule.scanners,
        vulnerabilities_allowed: approval_rule.vulnerabilities_allowed,
        severity_levels: approval_rule.severity_levels,
        vulnerability_states: approval_rule.vulnerability_states
      }]
      actions = [{ type: 'require_approval', approvals_required: approval_rule.approvals_required }]
      user_ids = approval_rule.users.pluck(:id)
      actions[0][:user_approvers_ids] = user_ids if user_ids.present?
      group_ids = approval_rule.groups.pluck(:id)
      actions[0][:group_approvers_ids] = group_ids if group_ids.present?
      converted_policy = {
        type: 'scan_result_policy',
        name: policy_name,
        description: POLICY_DESCRIPTION,
        enabled: true,
        rules: rules,
        actions: actions
      }
      commit_params = { name: converted_policy[:name], policy_yaml: converted_policy.to_yaml, operation: :append }
      commit_params[:branch_name] = orchestration_project.default_branch_or_main if override_branch_name
      commit_params
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_merge_request(source_branch)
      merge_request_params = {
        title: MERGE_REQUEST_TITLE,
        description: MERGE_REQUEST_DESCRIPTION,
        source_branch: source_branch,
        target_branch: orchestration_project.default_branch_or_main,
        assignees: [assignee],
        merge_user: current_user
      }
      merge_request_result = MergeRequests::CreateService.new(
        project: orchestration_project,
        current_user: current_user,
        params: merge_request_params
      ).execute

      unless merge_request_result&.persisted?
        raise "Failed to create merge request: #{merge_request_result&.errors&.messages}"
      end
    end

    def create_orchestration_project
      orchestration_project_response = ::Security::SecurityOrchestrationPolicies::ProjectCreateService.new(
        container: project,
        current_user: current_user
      ).execute

      if orchestration_project_response[:status] == :error
        raise "Failed to create orchestration project: #{orchestration_project_response}"
      end
    end

    def create_commit(policy_name, override_branch_name = true)
      commit_result = ::Security::SecurityOrchestrationPolicies::PolicyCommitService.new(
        container: project,
        current_user: current_user,
        params: policy_commit_params(policy_name, override_branch_name)
      ).execute

      if commit_result[:status] != :success
        raise "Failed to create commit: #{commit_result}"
      end

      commit_result
    end

    def orchestration_project
      @orchestration_project ||= project
        .reset
        .security_orchestration_policy_configuration
        &.security_policy_management_project
    end

    def current_user
      @current_user ||= access_token.user
    end

    def update_security_project
      policy_name = POLICY_NAME
      if orchestration_project
        # To avoid duplications which would cause: Failed to create commit: {:message=>"Policy...", :status=>:error}
        policy_name = "#{POLICY_NAME}/#{Time.now.to_i}"

        commit_result = create_commit(policy_name, false)

        create_merge_request(commit_result[:branch])

        # Delete Vulnerability-Check rule
        approval_rule.delete
      else
        create_orchestration_project

        create_commit(policy_name)

        # Convert rule from vulnerability to scan_finding
        approval_rule.update!(name: policy_name, report_type: :scan_finding)
      end
    end

    def revoke_access_token
      return unless access_token

      ResourceAccessTokens::RevokeService.new(User.migration_bot, project.namespace, access_token).execute
    end

    def assignee
      orchestration_project.merge_requests.merged.last&.merge_event&.author ||
      orchestration_project.team.owners.first
    end
  end
end
