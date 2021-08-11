# frozen_string_literal: true

module Projects
  module Security
    class PoliciesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action :authorize_security_orchestration_policies!
      before_action :validate_policy_configuration, only: :edit

      before_action do
        push_frontend_feature_flag(:security_orchestration_policies_configuration, project)
        check_feature_flag!
      end

      feature_category :security_orchestration

      def index
        render :index, locals: { project: project }
      end

      def edit
        @policy_name = URI.decode_www_form_component(params[:id])
        @policy_type = params[:type]

        result = ::Security::SecurityOrchestrationPolicies::FetchPolicyService
                  .new(policy_configuration: policy_configuration, name: @policy_name, type: @policy_type.to_sym)
                  .execute
        @policy = result[:policy]

        return render_404 if @policy.blank?

        render :edit
      end

      private

      def validate_policy_configuration
        type = params[:type]
        result = ::Security::SecurityOrchestrationPolicies::PolicyConfigurationValidationService
          .new(policy_configuration: policy_configuration, type: (type.to_sym if type)).execute

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

      def policy_configuration
        @policy_configuration ||= project.security_orchestration_policy_configuration
      end

      def check_feature_flag!
        render_404 if Feature.disabled?(:security_orchestration_policies_configuration, project)
      end
    end
  end
end
