# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', :orchestrated, :smtp, product_group: :respond,
    quarantine: {
      type: :bug,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/397133'
    } do
    describe 'Alert with escalation policy' do
      let(:project) { create(:project, name: 'project-for-alert', description: 'Project for alert') }
      let(:rotation_schedule_name) { Faker::Lorem.sentence }
      let(:escalation_policy_name) { Faker::Lorem.sentence }
      let(:mail_hog_api) { Vendor::MailHog::API.new }
      let(:alert_email_subject) { "#{project.name} | Alert: #{rotation_schedule_name}" }

      let(:alert_payload) do
        { title: rotation_schedule_name, description: rotation_schedule_name }
      end

      before do
        Flow::Login.sign_in
        project.visit!
        add_oncall_schedule
        add_user_to_oncall_rotation
        set_escalation_policy
        send_test_alert
      end

      it(
        'notifies on-call user via system note and email on new alert',
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393448'
      ) do
        Page::Project::Menu.perform(&:go_to_monitor_alerts)
        Page::Project::Monitor::Alerts::Index.perform do |index|
          index.go_to_alert(rotation_schedule_name)
        end

        Page::Project::Monitor::Alerts::Show.perform do |show|
          show.go_to_activity_feed_tab
          expect(show).to have_system_note("alert via escalation policy #{escalation_policy_name}")
        end

        expect { email_subjects }.to eventually_include(alert_email_subject).within(max_duration: 300)
      end

      private

      def add_oncall_schedule
        Page::Project::Menu.perform(&:go_to_monitor_on_call_schedules)
        EE::Page::Project::Monitor::OnCallSchedule::New.perform do |new|
          new.open_add_schedule_modal
          new.set_schedule_name(name: rotation_schedule_name)
          new.select_timezone
          new.save_new_schedule
        end
      end

      def add_user_to_oncall_rotation
        EE::Page::Project::Monitor::OnCallSchedule::Index.perform do |index|
          index.open_add_rotation_modal
          index.set_start_date
          index.set_rotation_name
          index.select_participant
          index.save_new_rotation
        end
      end

      def set_escalation_policy
        Page::Project::Menu.perform(&:go_to_monitor_escalation_policies)
        EE::Page::Project::Monitor::EscalationPolicies::New.perform do |new|
          new.open_new_policy_modal
          new.set_policy_name(name: escalation_policy_name)
          new.select_schedule(rotation_schedule_name)
          new.save_new_policy
        end
      end

      def send_test_alert
        Flow::AlertSettings.go_to_monitor_settings
        Flow::AlertSettings.setup_http_endpoint_integration
        Flow::AlertSettings.send_test_alert(payload: alert_payload)
      end

      def mail_hog_messages
        Runtime::Logger.debug('Fetching email...')

        messages = mail_hog_api.fetch_messages
        logs = messages.map { |m| "#{m.to}: #{m.subject}" }

        Runtime::Logger.debug("MailHog Logs: #{logs.join("\n")}")

        messages
      end

      def email_subjects
        mail_hog_messages.map(&:subject)
      end
    end
  end
end
