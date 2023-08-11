# frozen_string_literal: true

# The Smocker service is used by a few tests so the instance variable avoids needless creating and destroying,
# especially the mock service that causes flakiness if it's started and stopped for each test.
# rubocop: disable RSpec/InstanceVariable
module QA
  # Redefine the constant because it's too long when it's used in the spec
  StreamDestination = QA::EE::Resource::InstanceAuditEventExternalDestination
  RSpec.describe(
    'Govern',
    :requires_admin,
    :skip_live_env, # We need to enable local requests to use a local mock streaming server
    product_group: :compliance
  ) do
    describe 'Instance audit event streaming' do
      let(:target_details) { entity_path }
      let(:headers) { @headers }

      before(:context) do
        @event_types = %w[remove_ssh_key group_created project_created user_created repository_git_operation]
        @headers = {
          'Test-Header1': 'instance event streaming',
          'Test-Header2': 'destination via api'
        }

        Runtime::ApplicationSettings.enable_local_requests

        # Set up smocker as a mock streaming event destination
        @mock_service = QA::Support::AuditEventStreamingService.new
        @stream_destination = StreamDestination.fabricate_via_api! do |resource|
          resource.destination_url = @mock_service.url('logs')
        end
        @stream_destination.add_headers(@headers)
        @stream_destination.add_filters(@event_types)

        @mock_service.wait_for_streaming_to_start(event_type: 'remove_ssh_key', entity_type: 'User') do
          Resource::SSHKey.fabricate_via_api!.remove_via_api!
        end
      end

      after(:context) do
        @mock_service&.teardown!
        @stream_destination&.remove_via_api!

        Runtime::ApplicationSettings.disable_local_requests
      end

      around do |example|
        @mock_service.reset!
        example.run
        next unless example.exception

        # If there is a failure this will output the logs from the smocker container (at the debug log level)
        Service::DockerRun::Smocker.logs
      end

      context 'when a group is created' do
        # Create a group within a group so that the test doesn't reuse a pre-existing group
        let!(:parent_group) { Resource::Group.fabricate! }
        let(:entity_path) do
          create(:group,
            sandbox: parent_group,
            name: "audit-event-streaming-#{Faker::Alphanumeric.alphanumeric(number: 8)}").full_path
        end

        include_examples 'streamed events', 'group_created', 'Group', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415874'
      end

      context 'when a project is created' do
        # Create a group first so its audit event is streamed before we check for the create project event
        let!(:group) { Resource::Group.fabricate! }
        let(:entity_path) { create(:project, group: group).full_path }

        include_examples 'streamed events', 'project_created', 'Project', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415875'
      end

      context 'when a user is created' do
        let(:entity_path) { create(:user).username }

        include_examples 'streamed events', 'user_created', 'User', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415876'
      end

      context 'when a repository is cloned via SSH' do
        # Create the project and key first so their audit events are streamed before we check for the clone event
        let!(:key) { Resource::SSHKey.fabricate_via_api! }
        let!(:project) do
          Resource::Project.fabricate! do |project|
            project.initialize_with_readme = true
          end
        end

        # Clone the repo via SSH and then use the project path and name to confirm the event details
        let(:target_details) { project.name }
        let(:entity_path) do
          Git::Repository.perform do |repository|
            repository.uri = project.repository_ssh_location.uri
            repository.use_ssh_key(key)
            repository.clone
          end

          project.full_path
        end

        include_examples 'streamed events', 'repository_git_operation', 'Project', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415972'
      end
    end
  end
end
# rubocop: enable RSpec/InstanceVariable
