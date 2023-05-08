# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  describe '.calculate_actual_state' do
    subject do
      described_class.new
    end

    context 'with cases parameterized from shared fixtures' do
      where(:previous_actual_state, :current_actual_state, :workspace_exists) do
        [
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409783
          #       These are currently taken from only the currently supported cases in
          #       remote_development_shared_contexts.rb#create_workspace_agent_info,
          #       but we should ensure they are providing full and
          #       realistic coverage of all possible relevant states.
          #       Note that `nil` is passed when the argument will not be used by
          #       remote_development_shared_contexts.rb
          [RemoteDevelopment::Workspaces::States::CREATION_REQUESTED, RemoteDevelopment::Workspaces::States::STARTING,
            nil],
          [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::STARTING, false],
          [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::RUNNING, false],
          [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::FAILED, false],
          [RemoteDevelopment::Workspaces::States::FAILED, RemoteDevelopment::Workspaces::States::STARTING, false],
          [RemoteDevelopment::Workspaces::States::RUNNING, RemoteDevelopment::Workspaces::States::FAILED, nil],
          [RemoteDevelopment::Workspaces::States::RUNNING, RemoteDevelopment::Workspaces::States::STOPPING, nil],
          [RemoteDevelopment::Workspaces::States::STOPPING, RemoteDevelopment::Workspaces::States::STOPPED, nil],
          [RemoteDevelopment::Workspaces::States::STOPPING, RemoteDevelopment::Workspaces::States::FAILED, nil],
          [RemoteDevelopment::Workspaces::States::STOPPED, RemoteDevelopment::Workspaces::States::STARTING, nil],
          [RemoteDevelopment::Workspaces::States::STOPPED, RemoteDevelopment::Workspaces::States::FAILED, nil],
          [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::STARTING, true],
          [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::RUNNING, true],
          [RemoteDevelopment::Workspaces::States::STARTING, RemoteDevelopment::Workspaces::States::FAILED, true],
          [RemoteDevelopment::Workspaces::States::FAILED, RemoteDevelopment::Workspaces::States::STARTING, true],
          [RemoteDevelopment::Workspaces::States::FAILED, RemoteDevelopment::Workspaces::States::STOPPING, nil],
          [nil, RemoteDevelopment::Workspaces::States::FAILED, nil]
        ]
      end

      with_them do
        let(:latest_k8s_deployment_info) do
          workspace_agent_info = create_workspace_agent_info(
            workspace_id: 1,
            workspace_name: 'name',
            workspace_namespace: 'namespace',
            agent_id: 1,
            owning_inventory: 'owning_inventory',
            resource_version: 1,
            previous_actual_state: previous_actual_state,
            current_actual_state: current_actual_state,
            workspace_exists: workspace_exists
          )
          workspace_agent_info.fetch('latest_k8s_deployment_info')
        end

        it 'calculates correct actual state' do
          calculated_actual_state = nil
          begin
            calculated_actual_state = subject.calculate_actual_state(
              latest_k8s_deployment_info: latest_k8s_deployment_info
            )
          rescue RemoteDevelopment::AgentInfoStatusFixtureNotImplementedError
            skip 'TODO: Properly implement the agent info status fixture for ' \
                 "previous_actual_state: #{previous_actual_state}, " \
                 "current_actual_state: #{current_actual_state}, " \
                 "workspace_exists: #{workspace_exists}"
          end
          expect(calculated_actual_state).to be(current_actual_state) if calculated_actual_state
        end
      end
    end

    # NOTE: The remaining examples below in this file existed before we added the RSpec parameterized
    #       section above with tests based on create_workspace_agent_info. Some of them may be
    #       redundant now.

    context 'when the deployment is completed successfully' do
      context 'when new workspace has been created or existing workspace has been scaled up' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::RUNNING }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                availableReplicas: 1
                conditions:
                - reason: MinimumReplicasAvailable
                  type: Available
                - reason: NewReplicaSetAvailable
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when existing workspace has been scaled down' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 0
              status:
                conditions:
                - reason: MinimumReplicasAvailable
                  type: Available
                - reason: NewReplicaSetAvailable
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when status does not contain required information' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::UNKNOWN }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                test: 0
              status:
                conditions:
                - reason: MinimumReplicasAvailable
                  type: Available
                - reason: NewReplicaSetAvailable
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end
    end

    context 'when the deployment is in progress' do
      context 'when new workspace has been created' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::STARTING }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                conditions:
                - reason: NewReplicaSetCreated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when existing workspace has been updated' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::STARTING }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                conditions:
                - reason: FoundNewReplicaSet
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when existing workspace has been scaled up' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::STARTING }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                conditions:
                - reason: ReplicaSetUpdated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when existing workspace has been scaled down' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::STOPPING }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 0
              status:
                conditions:
                - reason: ReplicaSetUpdated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when spec replicas is more than 1' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::UNKNOWN }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 2
              status:
                conditions:
                - reason: ReplicaSetUpdated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when status does not contain required information' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::UNKNOWN }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                conditions:
                - reason: test
                  type: test
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end
    end

    context 'when the deployment is failed' do
      context 'when new workspace has been created or existing workspace has been scaled up' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::FAILED }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                conditions:
                - reason: MinimumReplicasUnavailable
                  type: Available
                - reason: ProgressDeadlineExceeded
                  type: Progressing
                unavailableReplicas: 1
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when existing scaled down workspace which was failing has been scaled up' do
        let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::FAILED }
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 1
              status:
                conditions:
                - reason: MinimumReplicasUnavailable
                  type: Available
                - reason: NewReplicaSetAvailable
                  type: Progressing
                unavailableReplicas: 1
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          pending "This currently returns STARTING state. See related TODOs in the relevant code."
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end
    end

    context 'when the deployment status is unknown' do
      let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::UNKNOWN }

      context 'when spec is missing' do
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              test:
                replicas: 0
              status:
                conditions:
                - reason: ReplicaSetUpdated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when spec replicas is missing' do
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                test: 0
              status:
                conditions:
                - reason: ReplicaSetUpdated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when status is missing' do
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 0
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when status conditions is missing' do
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 0
              status:
                test:
                - reason: ReplicaSetUpdated
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when status conditions reason is missing' do
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 0
              status:
                conditions:
                - type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end

      context 'when status progressing and available conditions are unrecognized' do
        let(:latest_k8s_deployment_info) do
          YAML.safe_load(
            <<~WORKSPACE_STATUS_YAML
              spec:
                replicas: 0
              status:
                conditions:
                - reason: unrecognized
                  type: Available
                - reason: unrecognized
                  type: Progressing
          WORKSPACE_STATUS_YAML
          )
        end

        it 'returns the expected actual state' do
          expect(subject.calculate_actual_state(latest_k8s_deployment_info: latest_k8s_deployment_info))
            .to be(expected_actual_state)
        end
      end
    end

    context 'when termination_progress is Terminating' do
      let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::TERMINATING }
      let(:termination_progress) { RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator::TERMINATING }

      it 'returns the expected actual state' do
        expect(
          subject.calculate_actual_state(
            latest_k8s_deployment_info: nil,
            termination_progress: termination_progress
          )
        ).to be(expected_actual_state)
      end
    end

    context 'when termination_progress is Terminated' do
      let(:expected_actual_state) { RemoteDevelopment::Workspaces::States::TERMINATED }
      let(:termination_progress) { RemoteDevelopment::Workspaces::Reconcile::ActualStateCalculator::TERMINATED }

      it 'returns the expected actual state' do
        expect(
          subject.calculate_actual_state(
            latest_k8s_deployment_info: nil,
            termination_progress: termination_progress
          )
        ).to be(expected_actual_state)
      end
    end
  end
end
