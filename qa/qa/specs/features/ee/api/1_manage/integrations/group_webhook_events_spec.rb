# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe(
      'Group WebHooks integration',
      :requires_admin,
      :integrations,
      :orchestrated,
      product_group: :import_and_integrate
    ) do
      before(:context) do
        toggle_local_requests(true)
      end

      after(:context) do
        EE::Resource::GroupWebHook.teardown!
      end

      let(:session) { SecureRandom.hex(5) }

      it 'sends subgroup events',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/383580' do
        EE::Resource::GroupWebHook.setup(session: session, subgroup: true) do |webhook, smocker|
          group = Resource::Group.fabricate_via_api! do |group|
            group.sandbox = webhook.group
          end

          group.immediate_remove_via_api!

          expect { smocker.events(session).size }.to eventually_eq(2)
                                               .within(max_duration: 30, sleep_interval: 2),
            -> { "Should have 2 events, got: #{smocker.stringified_history(session)}" }

          events = smocker.events(session)

          expect(events).to include(
            a_hash_including(event_name: 'subgroup_create'),
            a_hash_including(event_name: 'subgroup_destroy')
          ),
            "Expected Create/Destroy Subgroup events, got: #{smocker.stringified_history(session)}"
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
          EE::Resource::GroupWebHook.setup(fail_mock, session: session, issues: true) do |webhook, smocker|
            project = Resource::Project.fabricate_via_api! do |project|
              project.group = webhook.group
            end

            hook_trigger_times.times do
              Resource::Issue.fabricate_via_api! do |issue_init|
                issue_init.project = project
              end

              # WebHook events are delayed/async, so giving a chance
              # for the auto-disabler to catch up
              sleep 0.5
            end

            expect { smocker.history(session).size }.to eventually_eq(hook_trigger_times)
                                                  .within(max_duration: 30, sleep_interval: 2),
              -> { "Should have #{hook_trigger_times} events, got: #{smocker.stringified_history(session)}" }

            webhook.reload!

            expect(webhook.alert_status).to eql('executable')
          end
        end
      end
    end

    private

    def toggle_local_requests(on)
      Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: on)
    end
  end
end
