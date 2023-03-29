# frozen_string_literal: true

module Projects
  module Security
    class PoliciesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action :authorize_read_security_orchestration_policies!, except: :edit
      before_action :authorize_modify_security_policy!, only: :edit
      before_action :validate_policy_configuration, only: :edit

      before_action do
        push_frontend_feature_flag(:scan_result_role_action, project)
      end

      feature_category :security_policy_management
      urgency :default, [:edit]
      urgency :low, [:index, :new]

      def index
        render :index, locals: { project: project }
      end

      def edit
        @policy_name = URI.decode_www_form_component(params[:id])
        @policy = policy
        @approvers = approvers

        render_404 if @policy.nil?
      end

      def schema
        render json: ::Security::OrchestrationPolicyConfiguration::POLICY_SCHEMA_JSON
      end

      private

      def validate_policy_configuration
        @policy_type = params[:type].presence&.to_sym
        result = ::Security::SecurityOrchestrationPolicies::PolicyConfigurationValidationService.new(
          policy_configuration: policy_configuration,
          type: @policy_type
        ).execute

        if result[:status] == :error
          case result[:invalid_component]
          when :policy_configuration, :parameter
            redirect_to project_security_policies_path(project), alert: result[:message]
          when :policy_project
            redirect_to project_path(policy_configuration.security_policy_management_project)
          when :policy_yaml
            policy_management_project = policy_configuration.security_policy_management_project
            policy_path = File.join(policy_management_project.default_branch, ::Security::OrchestrationPolicyConfiguration::POLICY_PATH)

            redirect_to project_blob_path(policy_management_project, policy_path), alert: result[:message]
          else
            redirect_to project_security_policies_path(project), alert: result[:message]
          end
        end
      end

      def policy
        result = ::Security::SecurityOrchestrationPolicies::FetchPolicyService.new(
          policy_configuration: policy_configuration,
          name: @policy_name,
          type: @policy_type
        ).execute

        result[:policy].presence
      end

      def policy_configuration
        @policy_configuration ||= project.security_orchestration_policy_configuration
      end

      def approvers
        return unless @policy_type == :scan_result_policy

        result = ::Security::SecurityOrchestrationPolicies::FetchPolicyApproversService.new(
          policy: @policy,
          container: project,
          current_user: @current_user
        ).execute

        return unless result[:status] == :success

        API::Entities::UserBasic.represent(result[:users]) +
          API::Entities::PublicGroupDetails.represent(result[:groups]) +
          result[:roles]
      end
    end
  end
end
