# frozen_string_literal: true

module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include DescriptionDiffActions
        include GeoInstrumentation
        include GitlabSubscriptions::SeatCountAlert

        before_action :disable_query_limiting_ee, only: [:update]
        before_action only: [:new, :create] do
          populate_vulnerability_id
        end

        before_action only: :show do
          push_licensed_feature(:escalation_policies, project)
          push_frontend_feature_flag(:real_time_issue_weight, project)
          push_force_frontend_feature_flag(:summarize_comments, can?(current_user, :summarize_notes, issue))
        end

        before_action :redirect_if_test_case, only: [:show]

        before_action only: :index do
          push_force_frontend_feature_flag(:okrs_mvc, project&.okrs_mvc_feature_flag_enabled?)
          push_licensed_feature(:okrs, project)
        end

        before_action only: %i[show index] do
          @seat_count_data = generate_seat_count_alert_data(@project)
        end

        feature_category :team_planning, [:delete_description_version, :description_diff]
        urgency :low, [:delete_description_version, :description_diff]
      end

      private

      def issue_params_attributes
        attrs = super
        attrs.unshift(:weight) if project.feature_available?(:issue_weights)
        attrs.unshift(:epic_id) if project.group&.feature_available?(:epics)
        attrs.unshift(:sprint_id) if project.group&.feature_available?(:iterations)

        attrs
      end

      override :finder_options
      def finder_options
        options = super

        return super if project.feature_available?(:issue_weights)

        options.reject { |key| key == 'weight' }
      end

      def disable_query_limiting_ee
        ::Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/issues/4794')
      end

      def issue_params
        super.tap do |params|
          if vulnerability_id
            params.merge!(vulnerability_issue_build_parameters)
          end
        end
      end

      def create_vulnerability_issue_feedback(issue)
        return unless issue.persisted? && vulnerability

        result = VulnerabilityFeedback::CreateService.new(
          issue.project,
          current_user,
          vulnerability_issue_feedback_params(issue, vulnerability)
        ).execute
        show_error = result[:message].errors.any?

        flash[:raw] = render_vulnerability_link_alert.html_safe if show_error
      end

      def vulnerability
        project.vulnerabilities.find(vulnerability_id) if vulnerability_id
      end

      def vulnerability_issue_build_parameters
        issue = params[:issue]

        {
          title: issue.fetch(:title, _("Investigate vulnerability: %{title}") % { title: vulnerability.title }),
          description: issue.fetch(:description, render_vulnerability_description),
          confidential: issue.fetch(:confidential, true)
        }
      end

      def vulnerability_issue_feedback_params(issue, vulnerability)
        feedback_params = {
          issue: issue,
          feedback_type: 'issue',
          category: vulnerability.report_type,
          project_fingerprint: vulnerability.finding.project_fingerprint,
          finding_uuid: vulnerability.finding_uuid,
          vulnerability_data: vulnerability.as_json
        }

        feedback_params[:vulnerability_data][:vulnerability_id] = vulnerability.id

        feedback_params
      end

      def render_vulnerability_description
        render_to_string(
          template: 'vulnerabilities/issue_description',
          formats: :md,
          locals: { vulnerability: vulnerability.present }
        )
      end

      def render_vulnerability_link_alert
        render_to_string(
          partial: 'vulnerabilities/unable_to_link_vulnerability',
          formats: :html,
          locals: {
            vulnerability_link: vulnerability_path(vulnerability)
          }
        )
      end

      def populate_vulnerability_id
        self.vulnerability_id = params[:vulnerability_id] if can?(current_user, :read_security_resource, project)
      end

      def redirect_if_test_case
        return unless issue.test_case?

        redirect_to project_quality_test_case_path(project, issue)
      end
    end
  end
end
