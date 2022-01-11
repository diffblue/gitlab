# frozen_string_literal: true

module Projects
  module Security
    class VulnerabilitiesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include SecurityDashboardsPermissions
      include IssuableActions
      include RendersNotes

      before_action do
        push_frontend_feature_flag(:create_vulnerability_jira_issue_via_graphql, @project, default_enabled: :yaml)
        push_frontend_feature_flag(:secure_vulnerability_training, @project, default_enabled: :yaml)
      end

      before_action :vulnerability, except: [:index, :new]
      before_action :authorize_create_vulnerability!, only: :new

      alias_method :vulnerable, :project

      feature_category :vulnerability_management

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
