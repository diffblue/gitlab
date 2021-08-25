# frozen_string_literal: true

require_relative '../../../browser_ui/8_monitor/cluster_with_prometheus'

module QA
  RSpec.describe 'Monitor', :orchestrated, :kubernetes, :requires_admin, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/241448', type: :investigating } do
    include_context "cluster with Prometheus installed"

    before do
      Flow::Login.sign_in_unless_signed_in
      @project.visit!
    end

    it 'allows configuration of alerts', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/869' do
      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        verify_metrics(on_dashboard)
        verify_add_alert(on_dashboard)
        verify_edit_alert(on_dashboard)
        verify_persist_alert(on_dashboard)
        verify_delete_alert(on_dashboard)
      end
    end

    it 'creates an incident template and opens an incident with template applied', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/981' do
      create_incident_template

      Page::Project::Menu.perform(&:go_to_monitor_settings)

      Page::Project::Settings::Monitor.perform do |settings|
        settings.expand_incidents do |incident_settings|
          incident_settings.enable_issues_for_incidents
          incident_settings.select_issue_template('incident')
          incident_settings.save_incident_settings
        end
      end

      create_incident_issue

      Page::Project::Issue::Show.perform do |issue|
        expect(issue).to have_metrics_unfurled
      end
    end

    private

    def verify_metrics(on_dashboard)
      on_dashboard.wait_for_metrics

      expect(on_dashboard).to have_metrics
      expect(on_dashboard).not_to have_alert
    end

    def verify_add_alert(on_dashboard)
      on_dashboard.write_first_alert('>', 0)

      expect(on_dashboard).to have_alert
    end

    def verify_edit_alert(on_dashboard)
      on_dashboard.write_first_alert('<', 0)

      expect(on_dashboard).to have_alert('<')
    end

    def verify_persist_alert(on_dashboard)
      on_dashboard.refresh
      on_dashboard.wait_for_metrics
      on_dashboard.wait_for_alert('<')

      expect(on_dashboard).to have_alert('<')
    end

    def verify_delete_alert(on_dashboard)
      on_dashboard.delete_first_alert

      expect(on_dashboard).not_to have_alert('<')
    end

    def create_incident_template
      Page::Project::Menu.perform(&:go_to_monitor_metrics)

      chart_link = Page::Project::Monitor::Metrics::Show.perform do |on_dashboard|
        on_dashboard.wait_for_metrics
        on_dashboard.copy_link_to_first_chart
      end

      incident_template = "Incident Metric: #{chart_link}"
      push_template_to_repository(incident_template)
    end

    def push_template_to_repository(template)
      @project.visit!

      Page::Project::Show.perform(&:create_new_file!)

      Page::File::Form.perform do |form|
        form.add_name('.gitlab/issue_templates/incident.md')
        form.add_content(template)
        form.add_commit_message('Add Incident template')
        form.commit_changes
      end
    end

    def create_incident_issue
      Page::Project::Menu.perform(&:go_to_monitor_incidents)

      Page::Project::Monitor::Incidents::Index.perform do |incidents_page|
        incidents_page.create_incident
      end

      Page::Project::Issue::New.perform do |new_issue|
        new_issue.fill_title('test incident')
        new_issue.create_new_issue
      end
    end
  end
end
