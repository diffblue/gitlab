# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe(
      'Group WebHooks integration',
      :requires_admin,
      :integrations,
      :orchestrated,
      product_group: :integrations
    ) do
      before(:context) do
        toggle_local_requests(true)
      end

      after(:context) do
        Service::DockerRun::Smocker.teardown!
      end

      let(:session) { SecureRandom.hex(5) }

      it 'sends subgroup events',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383580' do
        setup_group_webhook(subgroup: true) do |webhook, smocker|
          group = Resource::Group.fabricate_via_api! do |group|
            group.sandbox = webhook.group
          end

          group.immediate_remove_via_api!

          expect { history(smocker).size }.to eventually_eq(2)
                                               .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have 2 events, got: #{event_logs(smocker)}" }

          event_names = events(smocker).map(&:event_name)
          expect(event_names).to include(:subgroup_create, :subgroup_destroy),
            -> { "Expected Create/Destroy Subgroup events, got: #{event_logs(smocker)}" }
        end
      end

      context 'when hook fails' do
        let(:fail_mock) do
          <<~YAML
            - request:
                method: POST
                path: /default
              response:
                status: 500
                headers:
                  Content-Type: text/plain
                body: 'webhook failed'
          YAML
        end

        let(:hook_trigger_times) { 6 }

        it 'group hooks do not auto-disable',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/389594' do
          setup_group_webhook(fail_mock, issues: true) do |webhook, smocker|
            project = Resource::Project.fabricate_via_api! do |project|
              project.group = webhook.group
            end

            hook_trigger_times.times do
              Resource::Issue.fabricate_via_api! do |issue_init|
                issue_init.project = project
              end
            end

            expect { history(smocker).size }.to eventually_eq(hook_trigger_times)
                                                  .within(max_duration: 30, sleep_interval: 2),
              -> { "Should have #{hook_trigger_times} events, got: #{event_logs(smocker)}" }

            webhook.reload!

            expect(webhook.alert_status).to eql('executable')
          end
        end
      end

      private

      def setup_group_webhook(mock = Vendor::Smocker::SmockerApi::DEFAULT_MOCK, **event_args)
        Service::DockerRun::Smocker.init(wait: 10) do |smocker|
          smocker.register(mock, session: session)

          webhook = EE::Resource::GroupWebHook.fabricate_via_api! do |hook|
            hook.url = smocker.url

            event_args.each do |event, bool|
              hook.send("#{event}_events=", bool)
            end
          end

          yield(webhook, smocker)

          smocker.reset
        end
      end

      # @param [Vendor::Smocker::SmockerApi] smocker
      def event_logs(smocker)
        events(smocker).map(&:raw).join("\n")
      end

      # @param [Vendor::Smocker::SmockerApi] smocker
      def events(smocker)
        history(smocker).map(&:as_hook_event)
      end

      # @param [Vendor::Smocker::SmockerApi] smocker
      def history(smocker)
        smocker.history(session)
      end

      def toggle_local_requests(on)
        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: on)
      end
    end
  end
end
