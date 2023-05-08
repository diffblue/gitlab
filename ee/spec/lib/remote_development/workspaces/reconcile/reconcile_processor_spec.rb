# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Workspaces::Reconcile::ReconcileProcessor, :freeze_time, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  describe '#process' do
    shared_examples 'max_hours_before_termination handling' do
      it 'sets desired_state to Terminated' do
        _, error = subject.process(agent: agent, workspace_agent_infos: workspace_agent_infos, update_type: update_type)
        expect(error).to be_nil

        expect(workspace.reload.desired_state).to eq(RemoteDevelopment::Workspaces::States::TERMINATED)
      end
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:agent) { create(:ee_cluster_agent, :with_remote_development_agent_config) }
    let(:expected_value_for_started) { true }

    subject do
      described_class.new
    end

    context 'when update_type is full' do
      let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateType::FULL }

      it 'updates workspace record and returns proper workspace_rails_info entry' do
        create(:workspace, agent: agent, user: user)
        payload, error = subject.process(agent: agent, workspace_agent_infos: [], update_type: update_type)
        expect(error).to be_nil
        workspace_rails_infos = payload.fetch(:workspace_rails_infos)
        expect(workspace_rails_infos.length).to eq(1)
        workspace_rails_info = workspace_rails_infos.first

        # NOTE: We don't care about any specific expectations, just that the existing workspace
        #       still has a config returned in the rails_info response even though it was not sent by the agent.
        expect(workspace_rails_info[:config_to_apply]).not_to be_nil
      end
    end

    context 'when update_type is partial' do
      let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateType::PARTIAL }

      context 'when receiving agent updates for a workspace which exists in the db' do
        let(:desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }
        let(:actual_state) { current_actual_state }
        let(:previous_actual_state) { RemoteDevelopment::Workspaces::States::STOPPING }
        let(:current_actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }
        let(:workspace_exists) { false }
        let(:deployment_resource_version_from_agent) { '2' }
        let(:expected_desired_state) { desired_state }
        let(:expected_actual_state) { actual_state }
        let(:expected_deployment_resource_version) { deployment_resource_version_from_agent }
        let(:expected_config_to_apply) { nil }
        let(:owning_inventory) { "#{workspace.name}-workspace-inventory" }

        let(:workspace_agent_info) do
          create_workspace_agent_info(
            workspace_id: workspace.id,
            workspace_name: workspace.name,
            workspace_namespace: workspace.namespace,
            agent_id: workspace.agent.id,
            owning_inventory: owning_inventory,
            resource_version: deployment_resource_version_from_agent,
            previous_actual_state: previous_actual_state,
            current_actual_state: current_actual_state,
            workspace_exists: workspace_exists
          )
        end

        let(:workspace_agent_infos) { [workspace_agent_info] }

        let(:expected_workspace_rails_info) do
          {
            name: workspace.name,
            namespace: workspace.namespace,
            desired_state: expected_desired_state,
            actual_state: expected_actual_state,
            deployment_resource_version: expected_deployment_resource_version,
            config_to_apply: expected_config_to_apply
          }
        end

        let(:expected_workspace_rails_infos) { [expected_workspace_rails_info] }

        let(:workspace) do
          create(
            :workspace,
            agent: agent,
            user: user,
            desired_state: desired_state,
            actual_state: actual_state
          )
        end

        context 'with max_hours_before_termination expired' do
          let(:workspace) do
            create(
              :workspace,
              :without_realistic_after_create_timestamp_updates,
              agent: agent,
              user: user,
              desired_state: desired_state,
              actual_state: actual_state,
              max_hours_before_termination: 24,
              created_at: 25.hours.ago
            )
          end

          context 'when state would otherwise be sent' do
            let(:desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }
            let(:actual_state) { RemoteDevelopment::Workspaces::States::RUNNING }

            it_behaves_like 'max_hours_before_termination handling'
          end

          context 'when desired_state is RestartRequested and actual_state is Stopped' do
            let(:desired_state) { RemoteDevelopment::Workspaces::States::RESTART_REQUESTED }
            let(:actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }

            it_behaves_like 'max_hours_before_termination handling'
          end
        end

        context 'with timestamp precondition checks' do
          # NOTE: rubocop:disable RSpec/ExpectInHook could be avoided with a helper method or custom expectation,
          #       but this works for now.
          # rubocop:disable RSpec/ExpectInHook
          before do
            # Ensure that both desired_state_updated_at and responded_to_agent_at are before Time.current,
            # so that we can test for any necessary differences after processing updates them
            # noinspection RubyResolve
            expect(workspace.desired_state_updated_at).to be_before(Time.current)
            # noinspection RubyResolve
            expect(workspace.responded_to_agent_at).to be_before(Time.current)
          end

          after do
            # After processing, the responded_to_agent_at should always have been updated
            workspace.reload
            # noinspection RubyResolve
            expect(workspace.responded_to_agent_at)
              .not_to be_before(workspace.desired_state_updated_at)
          end
          # rubocop:enable RSpec/ExpectInHook

          context 'when desired_state matches actual_state' do
            # rubocop:disable RSpec/ExpectInHook
            before do
              # noinspection RubyResolve
              expect(workspace.responded_to_agent_at)
                .to be_after(workspace.desired_state_updated_at)
            end
            # rubocop:enable RSpec/ExpectInHook

            context 'when state is Stopped' do
              let(:desired_state) { RemoteDevelopment::Workspaces::States::STOPPED }

              it 'updates workspace record and returns proper workspace_rails_info entry' do
                # verify initial states in db (sanity check of match between factory and fixtures)
                expect(workspace.desired_state).to eq(desired_state)
                expect(workspace.actual_state).to eq(actual_state)

                payload, error = subject.process(
                  agent: agent,
                  workspace_agent_infos: workspace_agent_infos,
                  update_type: update_type
                )
                expect(error).to be_nil
                workspace_rails_infos = payload.fetch(:workspace_rails_infos)
                expect(workspace_rails_infos.length).to eq(1)

                workspace.reload

                expect(workspace.desired_state).to eq(workspace.actual_state)
                expect(workspace.deployment_resource_version)
                  .to eq(expected_deployment_resource_version)

                expect(workspace_rails_infos).to eq(expected_workspace_rails_infos)
              end
            end

            context 'when state is Terminated' do
              let(:desired_state) { RemoteDevelopment::Workspaces::States::TERMINATED }
              let(:previous_actual_state) { RemoteDevelopment::Workspaces::States::TERMINATED }
              let(:current_actual_state) { RemoteDevelopment::Workspaces::States::TERMINATED }
              let(:expected_deployment_resource_version) { workspace.deployment_resource_version }

              it 'updates workspace record and returns proper workspace_rails_info entry' do
                # verify initial states in db (sanity check of match between factory and fixtures)
                expect(workspace.desired_state).to eq(desired_state)
                expect(workspace.actual_state).to eq(actual_state)

                # We could do this with a should_not_change block but this reads cleaner IMO
                payload, error = subject.process(
                  agent: agent,
                  workspace_agent_infos: workspace_agent_infos,
                  update_type: update_type
                )
                expect(error).to be_nil
                workspace_rails_infos = payload.fetch(:workspace_rails_infos)
                expect(workspace_rails_infos.length).to eq(1)

                workspace.reload

                expect(workspace.desired_state).to eq(workspace.actual_state)
                expect(workspace.deployment_resource_version)
                  .to eq(expected_deployment_resource_version)

                expect(workspace_rails_infos).to eq(expected_workspace_rails_infos)
              end
            end
          end

          context 'when desired_state does not match actual_state' do
            # noinspection RubyResolve
            let(:deployment_resource_version_from_agent) { workspace.deployment_resource_version }
            # noinspection RubyResolve
            let(:owning_inventory) { "#{workspace.name}-workspace-inventory" }

            # noinspection RubyResolve
            let(:expected_config_to_apply) do
              create_config_to_apply(
                workspace_id: workspace.id,
                workspace_name: workspace.name,
                workspace_namespace: workspace.namespace,
                agent_id: workspace.agent.id,
                owning_inventory: owning_inventory,
                started: expected_value_for_started
              )
            end

            let(:expected_workspace_rails_infos) { [expected_workspace_rails_info] }

            # rubocop:disable RSpec/ExpectInHook
            before do
              # noinspection RubyResolve
              expect(workspace.responded_to_agent_at)
                .to be_before(workspace.desired_state_updated_at)
            end
            # rubocop:enable RSpec/ExpectInHook

            context 'when desired_state is Running' do
              let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }

              # noinspection RubyResolve
              it 'returns proper workspace_rails_info entry with config_to_apply' do
                # verify initial states in db (sanity check of match between factory and fixtures)
                expect(workspace.desired_state).to eq(desired_state)
                expect(workspace.actual_state).to eq(actual_state)

                payload, error = subject.process(
                  agent: agent,
                  workspace_agent_infos: workspace_agent_infos,
                  update_type: update_type
                )
                expect(error).to be_nil
                workspace_rails_infos = payload.fetch(:workspace_rails_infos)
                expect(workspace_rails_infos.length).to eq(1)

                workspace.reload

                expect(workspace.deployment_resource_version)
                  .to eq(expected_deployment_resource_version)

                # test the config to apply first to get a more specific diff if it fails
                # noinspection RubyResolve
                provisioned_workspace_rails_info =
                  workspace_rails_infos.detect { |info| info.fetch(:name) == workspace.name }
                expect(provisioned_workspace_rails_info.fetch(:config_to_apply))
                  .to eq(expected_workspace_rails_info.fetch(:config_to_apply))

                # then test everything in the infos
                expect(workspace_rails_infos).to eq(expected_workspace_rails_infos)
              end
            end

            context 'when desired_state is Terminated' do
              let(:desired_state) { RemoteDevelopment::Workspaces::States::TERMINATED }
              let(:expected_value_for_started) { false }

              # noinspection RubyResolve
              it 'returns proper workspace_rails_info entry with config_to_apply' do
                # verify initial states in db (sanity check of match between factory and fixtures)
                expect(workspace.desired_state).to eq(desired_state)
                expect(workspace.actual_state).to eq(actual_state)

                payload, error = subject.process(
                  agent: agent,
                  workspace_agent_infos: workspace_agent_infos,
                  update_type: update_type
                )
                expect(error).to be_nil
                workspace_rails_infos = payload.fetch(:workspace_rails_infos)
                expect(workspace_rails_infos.length).to eq(1)

                workspace.reload

                expect(workspace.deployment_resource_version)
                  .to eq(expected_deployment_resource_version)

                # test the config to apply first to get a more specific diff if it fails
                # noinspection RubyResolve
                provisioned_workspace_rails_info =
                  workspace_rails_infos.detect { |info| info.fetch(:name) == workspace.name }
                expect(provisioned_workspace_rails_info.fetch(:config_to_apply))
                  .to eq(expected_workspace_rails_info.fetch(:config_to_apply))

                # then test everything in the infos
                expect(workspace_rails_infos).to eq(expected_workspace_rails_infos)
              end
            end

            context 'when desired_state is RestartRequested and actual_state is Stopped' do
              let(:desired_state) { RemoteDevelopment::Workspaces::States::RESTART_REQUESTED }
              let(:expected_desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }

              # noinspection RubyResolve
              it 'changes desired_state to Running' do
                # verify initial states in db (sanity check of match between factory and fixtures)
                expect(workspace.desired_state).to eq(desired_state)
                expect(workspace.actual_state).to eq(actual_state)

                payload, error = subject.process(agent: agent,
                  workspace_agent_infos: workspace_agent_infos,
                  update_type: update_type
                )
                expect(error).to be_nil
                workspace_rails_infos = payload.fetch(:workspace_rails_infos)
                expect(workspace_rails_infos.length).to eq(1)

                workspace.reload
                expect(workspace.desired_state).to eq(expected_desired_state)

                # test the config to apply first to get a more specific diff if it fails
                # noinspection RubyResolve
                provisioned_workspace_rails_info =
                  workspace_rails_infos.detect { |info| info.fetch(:name) == workspace.name }
                expect(provisioned_workspace_rails_info[:config_to_apply])
                  .to eq(expected_workspace_rails_info.fetch(:config_to_apply))

                # then test everything in the infos
                expect(workspace_rails_infos).to eq(expected_workspace_rails_infos)
              end
            end

            context 'when actual_state is Unknown' do
              let(:current_actual_state) { RemoteDevelopment::Workspaces::States::UNKNOWN }

              it 'has test coverage for logging in conditional' do
                subject.process(agent: agent, workspace_agent_infos: workspace_agent_infos, update_type: update_type)
              end
            end
          end
        end
      end

      context 'when receiving agent updates for a workspace which does not exist in the db' do
        let(:workspace_name) { 'non-existent-workspace' }
        let(:workspace_namespace) { 'does-not-matter' }

        let(:workspace_agent_info) do
          create_workspace_agent_info(
            workspace_id: 1,
            workspace_name: workspace_name,
            workspace_namespace: workspace_namespace,
            agent_id: '1',
            owning_inventory: 'does-not-matter',
            resource_version: '42',
            previous_actual_state: RemoteDevelopment::Workspaces::States::STOPPING,
            current_actual_state: RemoteDevelopment::Workspaces::States::STOPPED,
            workspace_exists: false
          )
        end

        let(:workspace_agent_infos) { [workspace_agent_info] }

        let(:expected_workspace_rails_infos) { [] }

        it 'prints an error and does not attempt to update the workspace in the db' do
          payload, error = subject.process(
            agent: agent,
            workspace_agent_infos: workspace_agent_infos,
            update_type: update_type
          )
          expect(error).to be_nil
          workspace_rails_infos = payload.fetch(:workspace_rails_infos)
          expect(workspace_rails_infos).to be_empty
        end
      end

      context 'when new unprovisioned workspace exists in database"' do
        let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
        let(:actual_state) { RemoteDevelopment::Workspaces::States::CREATION_REQUESTED }

        let_it_be(:unprovisioned_workspace) do
          create(:workspace, :unprovisioned, agent: agent, user: user)
        end

        let(:workspace_agent_infos) { [] }

        # noinspection RubyResolve
        let(:owning_inventory) { "#{unprovisioned_workspace.name}-workspace-inventory" }

        # noinspection RubyResolve
        let(:expected_config_to_apply) do
          create_config_to_apply(
            workspace_id: unprovisioned_workspace.id,
            workspace_name: unprovisioned_workspace.name,
            workspace_namespace: unprovisioned_workspace.namespace,
            agent_id: unprovisioned_workspace.agent.id,
            owning_inventory: owning_inventory,
            started: expected_value_for_started
          )
        end

        # noinspection RubyResolve
        let(:expected_unprovisioned_workspace_rails_info) do
          {
            name: unprovisioned_workspace.name,
            namespace: unprovisioned_workspace.namespace,
            desired_state: desired_state,
            actual_state: actual_state,
            deployment_resource_version: nil,
            config_to_apply: expected_config_to_apply
          }
        end

        let(:expected_workspace_rails_infos) { [expected_unprovisioned_workspace_rails_info] }

        # noinspection RubyResolve
        it 'returns proper workspace_rails_info entry' do
          # verify initial states in db (sanity check of match between factory and fixtures)
          expect(unprovisioned_workspace.desired_state).to eq(desired_state)
          expect(unprovisioned_workspace.actual_state).to eq(actual_state)

          payload, error = subject.process(
            agent: agent,
            workspace_agent_infos: workspace_agent_infos,
            update_type: update_type
          )
          expect(error).to be_nil
          workspace_rails_infos = payload.fetch(:workspace_rails_infos)
          expect(workspace_rails_infos.length).to eq(1)

          # test the config to apply first to get a more specific diff if it fails
          # noinspection RubyResolve
          unprovisioned_workspace_rails_info =
            workspace_rails_infos.detect { |info| info.fetch(:name) == unprovisioned_workspace.name }
          expect(unprovisioned_workspace_rails_info.fetch(:config_to_apply))
            .to eq(expected_unprovisioned_workspace_rails_info.fetch(:config_to_apply))

          # then test everything in the infos
          expect(workspace_rails_infos).to eq(expected_workspace_rails_infos)
        end
      end
    end
  end
end
