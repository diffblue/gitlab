# frozen_string_literal: true

# The Smocker service is used by a few tests so the instance variable avoids needless creating and destroying
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

      before(:context) do
        # We use the time at the start of the test to limit the results we get from the audit events API
        @test_start = DateTime.now

        enable_local_requests

        # Set up smocker as a mock streaming event destination
        @stream_destination = StreamDestination.fabricate_via_api!(!@flag_enabled) do |resource|
          resource.destination_url = mock_service.url('logs')
        end
        wait_for_streaming_to_start
      end

      after(:context) do
        Service::DockerRun::Smocker.teardown!
        @stream_destination.remove_via_api! if @stream_destination

        restore_local_requests
      end

      after do |example|
        next unless example.exception

        # If there is a failure this will output the logs from the smocker container (at the debug log level)
        Service::DockerRun::Smocker.logs
      end

      shared_examples 'streamed events' do |event_type, entity_type, testcase|
        it 'received by an external server', testcase: testcase do
          entity_path # Call to trigger the event before we can check it was received
          event_record = wait_for_event(event_type, entity_type, entity_path)
          verify_response = mock_service.verify

          # Most of the verification is done via the last `expect` statement below using
          # the mocks in qa/qa/ee/fixtures/audit_event_streaming/mocks.yml
          # The other two are checks for data that couldn't be added to a mock in advance
          aggregate_failures do
            # Verification tokens are created for us if we don't provide one
            # https://docs.gitlab.com/ee/administration/audit_event_streaming/#verify-event-authenticity
            expect(event_record[:headers]).to include(
              "X-Gitlab-Event-Streaming-Token": [@stream_destination.verification_token])
            expect(event_record[:body]).to include(details: a_hash_including(target_details: target_details))
            expect(verify_response).to be_success,
              "Failures when verifying events received:\n#{JSON.pretty_generate(verify_response.failures)}"
          end
        end
      end

      context 'when a group is created' do
        # Create a group within a group so that the test doesn't reuse a pre-existing group
        let!(:parent_group) { Resource::Group.fabricate! }
        let(:entity_path) do
          Resource::Group.fabricate_via_api! do |group|
            group.sandbox = parent_group
            group.name = "audit-event-streaming-#{Faker::Alphanumeric.alphanumeric(number: 8)}"
          end.full_path
        end

        it_behaves_like 'streamed events', :group_created, 'Group', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415874'
      end

      context 'when a project is created' do
        # Create a group first so its audit event is streamed before we check for the create project event
        let!(:group) { Resource::Group.fabricate! }
        let(:entity_path) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = group
          end.full_path
        end

        it_behaves_like 'streamed events', :project_created, 'Project', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415875'
      end

      context 'when a user is created' do
        let(:entity_path) { Resource::User.fabricate_via_api!.username }

        it_behaves_like 'streamed events', :user_created, 'User', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415876'
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

        it_behaves_like 'streamed events', :repository_git_operation, 'Project', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/415972'
      end
    end

    # Enable the application setting that allows requests from local services to the GitLab instance
    #
    # @return [Void]
    def enable_local_requests
      @local_requests_allowed =
        Runtime::ApplicationSettings.get_application_setting(:allow_local_requests_from_web_hooks_and_services)

      Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)
    end

    # Disables the application setting that allows local requests. Does nothing if it was enabled before
    # calling `enable_local_requests`.
    #
    # @return [Void]
    def restore_local_requests
      Runtime::ApplicationSettings.set_application_settings(
        allow_local_requests_from_web_hooks_and_services: @local_requests_allowed
      )
    end

    # Create a mock external instance audit event streaming server using smocker
    #
    # @return [QA::Vendor::Smocker::SmockerApi] an API to access the smocker server
    def mock_service
      @smocker_service ||= Service::DockerRun::Smocker.init(wait: 10) do |smocker|
        smocker.reset
        smocker.register(mocks)
        smocker
      end
    end

    # The configuration for the mocked requests and responses for events that will be verified in this test
    #
    # @return [String]
    def mocks
      @mocks ||= File.read(EE::Runtime::Path.fixture('audit_event_streaming', 'mocks.yml'))
    end

    # Wait for the mock service to receive a request with the specified event type
    #
    # @param [Symbol] event_type the event to wait for
    # @param [String] entity_type the entity type of the event
    # @param [String] entity_path the event entity identifier
    # @param [Integer] wait the amount of time to wait for the event to be received
    # @param [Boolean] raise_on_failure raise an error if the event is not received
    # @return [Hash] the request
    def wait_for_event(event_type, entity_type, entity_path = nil, wait: 10, raise_on_failure: true)
      event = Support::Waiter.wait_until(max_duration: wait, sleep_interval: 1, raise_on_failure: raise_on_failure) do
        mock_service.history.find do |record|
          body = record.request[:body]
          body&.dig(:event_type) == event_type.to_s && body&.dig(:entity_type) == entity_type &&
            (!entity_path || body&.dig(:entity_path) == entity_path)
        end&.request
      end
      return event unless event.nil? && raise_on_failure

      # Get the audit events from the API to help troubleshoot failures
      audit_events = EE::Resource::AuditEvents.all(created_after: @test_start.iso8601, entity_type: entity_type)

      raise QA::Support::Repeater::WaitExceededError,
        "An event with type '#{event_type}'#{" and entity_path '#{entity_path}'" if entity_path} was not received. " \
        "Event history: #{mock_service.stringified_history}. " \
        "Audit events with entity_type '#{entity_type}': #{audit_events}"
    end

    # Wait for GitLab to be ready to start streaming audit events
    def wait_for_streaming_to_start
      # Create and then remove an SSH key and confirm that the mock streaming server received the event
      Support::Waiter.wait_until(max_duration: 60, sleep_interval: 1, message: 'Waiting for streaming to start') do
        Resource::SSHKey.fabricate_via_api!.remove_via_api!
        wait_for_event(:remove_ssh_key, 'User', wait: 2, raise_on_failure: false)
      end
    rescue QA::Support::Repeater::WaitExceededError
      # If there is a failure this will output the logs from the smocker container (at the debug log level)
      Service::DockerRun::Smocker.logs

      raise
    end
  end
end
# rubocop: enable RSpec/InstanceVariable
