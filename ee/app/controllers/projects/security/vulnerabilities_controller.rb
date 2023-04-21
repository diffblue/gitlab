# frozen_string_literal: true

module Projects
  module Security
    class VulnerabilitiesController < Projects::ApplicationController
      include IssuableActions

      before_action do
        push_frontend_feature_flag(:create_vulnerability_jira_issue_via_graphql, @project)
        push_frontend_feature_flag(:deprecate_vulnerabilities_feedback, @project)
        push_frontend_feature_flag(:dismissal_reason, @project)
        push_frontend_feature_flag(:openai_experimentation, @project)
        push_frontend_feature_flag(:explain_vulnerability, @project)
      end

      before_action :vulnerability, except: [:index, :new]
      before_action :authorize_admin_vulnerability!, except: [:show, :index, :discussions]
      before_action :authorize_read_vulnerability!, except: [:new, :update, :destroy, :bulk_update]

      alias_method :vulnerable, :project

      feature_category :vulnerability_management
      urgency :low

      def show
        pipeline = vulnerability.finding.first_finding_pipeline
        @pipeline = pipeline if Ability.allowed?(current_user, :read_pipeline, pipeline)
        @gfm_form = true
      end

      private

      def vulnerability
        @issuable = @noteable = @vulnerability ||= vulnerable.vulnerabilities.find(params[:id])
      end

      alias_method :issuable, :vulnerability
      alias_method :noteable, :vulnerability

      def issue_serializer
        IssueSerializer.new(current_user: current_user)
      end
    end
  end
end
