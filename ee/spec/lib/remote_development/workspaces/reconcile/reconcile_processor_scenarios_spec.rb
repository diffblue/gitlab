# frozen_string_literal: true

require 'spec_helper'

# TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - This spec is dense and cryptic. Make it better.
# TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Several scenarios from
#       https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/workspace-updates.md
#       are not yet implemented - most or all are related to ERROR or FAILURE states, because the fixtures are not yet
#       implemented.
RSpec.describe ::RemoteDevelopment::Workspaces::Reconcile::ReconcileProcessor, 'Partial Update Scenarios', feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let_it_be(:user) { create(:user) }

  # See following documentation for details on all scenarios:
  #
  # https://gitlab.com/gitlab-org/remote-development/gitlab-remote-development-docs/-/blob/main/doc/workspace-updates.md
  #
  # Columns:
  #
  # initial_db_state: Initial state of workspace in DB. nil for new workspace, 2-tuple of [desired_state, actual_state]
  #   for existing workspace.
  #
  # user_desired_state_update: Optional first request event. nil if there is no user action, symbol for state if there
  #   is a user action.
  #
  # agent_actual_state_updates: Array of actual state updates from agent. nil if agent reports no info for workspace,
  #   otherwise an array of [previous_actual_state, current_actual_state, workspace_exists]
  #   to be used as args when calling #create_workspace_agent_info to generate the workspace agent info fixture.
  #
  # response_expectations: Array corresponding to entries in agent_actual_state_updates, representing
  #   expected rails_info hash response to agent for the workspace. Array is a 2-tuple of booleans for
  #   [config_to_apply_present?, deployment_resource_version_present?].
  #
  # db_expectations: Array corresponding to entries in
  #  (initial_db_state + user_desired_state_update + agent_actual_state_updates).
  #  Array entry is nil, or 2-tuple of symbols for [desired_state, actual_state].

  # rubocop:disable Layout/LineLength, Style/TrailingCommaInArrayLiteral - for ease of reading and editing
  where(:initial_db_state, :user_desired_state_update, :agent_actual_state_updates, :response_expectations, :db_expectations) do
    [
      #
      # desired: Running / actual: CreationRequested -> desired: Running / actual: Running
      [nil, :running, [nil, [:creation_requested, :starting, false], [:starting, :running, true]], [[true, false], [false, true], [false, true]], [[:running, :creation_requested], [:running, :creation_requested], [:running, :starting], [:running, :running]]],
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: CreationRequested -> desired: Running / actual: Failed
      # [nil, :running, [nil, [:creation_requested, :starting, false], [:starting, :failed, false]], [[true, false], [false, true], [false, true]], [[:running, :creation_requested], [:running, :creation_requested], [:running, :starting], [:running, :failed]]],
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: CreationRequested -> desired: Running / actual: Error
      #
      # desired: Running / actual: Running -> desired: Stopped / actual: Stopped
      [[:running, :running], :stopped, [nil, [:running, :stopping, true], [:stopping, :stopped, false]], [[true, true], [false, true], [false, true]], [[:running, :running], [:stopped, :running], [:stopped, :running], [:stopped, :stopping], [:stopped, :stopped]]],
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Running -> desired: Stopped / actual: Failed
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Running -> desired: Stopped / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 -
      #       This should be able to pass once https://gitlab.com/gitlab-org/gitlab/-/issues/406565 is fixed.
      #       We may need to update ee/spec/support/shared_contexts/remote_development/remote_development_shared_contexts.rb
      #       and/or ee/lib/remote_development/actual_state_calculator.rb to make this pass, but need to see how it
      #       behaves in reality after the above issue is fixed in order to make the fixtures reflect reality.
      # desired: Running / actual: Running -> desired: Terminated / actual: Terminated
      # [[:running, :running], :terminated, [nil, [:running, :terminated, false]], [[true, true], [false, true]], [[:running, :running], [:terminated, :running], [:terminated, :running], [:terminated, :terminated]]],
      #
      # desired: Stopped / actual: Stopped -> desired: Running / actual: Running
      [[:stopped, :stopped], :running, [nil, [:stopped, :starting, false], [:starting, :running, true]], [[true, true], [false, true], [false, true]], [[:stopped, :stopped], [:running, :stopped], [:running, :stopped], [:running, :starting], [:running, :running]]],
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Running -> desired: Terminated / actual: Failed
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Running -> desired: Terminated / actual: Error
      #
      # desired: Stopped / actual: Stopped -> desired: Running / actual: Running
      [[:stopped, :stopped], :running, [nil, [:stopped, :starting, false], [:starting, :running, true]], [[true, true], [false, true], [false, true]], [[:stopped, :stopped], [:running, :stopped], [:running, :stopped], [:running, :starting], [:running, :running]]],
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Stopped / actual: Stopped -> desired: Running / actual: Failed
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Stopped / actual: Stopped -> desired: Running / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - This should be able to pass once
      #       https://gitlab.com/gitlab-org/gitlab/-/issues/406565 is fixed.
      #       We may need to update ee/spec/support/shared_contexts/remote_development/remote_development_shared_contexts.rb
      #       and/or ee/lib/remote_development/actual_state_calculator.rb to make this pass, but need to see how it
      #       behaves in reality after the above issue is fixed in order to make the fixtures reflect reality.
      # desired: Stopped / actual: Stopped -> desired: Terminated / actual: Terminated
      # [[:stopped, :stopped], :terminated, [nil, [:stopped, :terminated, false]], [[true, true], [false, true]], [[:stopped, :stopped], [:terminated, :stopped], [:terminated, :stopped], [:terminated, :terminated]]],
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Stopped / actual: Stopped -> desired: Terminated / actual: Failed
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Stopped / actual: Stopped -> desired: Terminated / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Running / actual: Running
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Stopped / actual: Stopped
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Stopped / actual: Failed
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Stopped / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Terminated / actual: Terminated
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Terminated / actual: Failed
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Failed -> desired: Terminated / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Error -> desired: Stopped / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # desired: Running / actual: Error -> desired: Terminated / actual: Error
      #
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409784 - Fixture not yet implemented...
      # Agent reports update for a workspace and user has also updated desired state of the workspace
      #
      # Restarting a workspace
      [[:running, :running], :restart_requested, [nil, [:running, :stopping, true], [:stopping, :stopped, false], [:stopped, :starting, false], [:starting, :running, true]], [[true, true], [false, true], [true, true], [false, true], [false, true]], [[:running, :running], [:restart_requested, :running], [:restart_requested, :running], [:restart_requested, :stopping], [:running, :stopped], [:running, :starting], [:running, :running]]],
      #
      # No update for workspace from agentk or from user
      #
    ]
  end
  # rubocop:enable Layout/LineLength, Style/TrailingCommaInArrayLiteral

  with_them do
    it 'behaves as expected' do
      # noinspection RubyResolve
      expected_db_expectations_length =
        (initial_db_state ? 1 : 0) + (user_desired_state_update ? 1 : 0) + agent_actual_state_updates.length
      # noinspection RubyResolve
      expect(db_expectations.length).to eq(expected_db_expectations_length)

      workspace = nil
      db_expectation_index = 0
      initial_resource_version = '1'

      # Handle initial db state, if necessary
      # noinspection RubyResolve
      if initial_db_state
        workspace = create(
          :workspace,
          desired_state: initial_db_state[0].to_s.camelize,
          actual_state: initial_db_state[1].to_s.camelize,
          deployment_resource_version: initial_resource_version
        )

        # assert on the workspace state in the db after initial creation
        expect(workspace.slice(:desired_state, :actual_state).values)
          .to eq(db_expectations[db_expectation_index].map(&:to_s).map(&:camelize))
        db_expectation_index += 1
      end

      # handle user desired state update, if necessary
      # noinspection RubyResolve
      if user_desired_state_update
        if workspace
          # noinspection RubyResolve
          workspace.update!(desired_state: user_desired_state_update.to_s.camelize)
        else
          workspace = create(:workspace, :unprovisioned)
        end

        # assert on the workspace state in the db after user desired state update
        expect(workspace.slice(:desired_state, :actual_state).values)
          .to eq(db_expectations[db_expectation_index].map(&:to_s).map(&:camelize))
        db_expectation_index += 1
      end

      raise 'Must have workspace by now, either from initial_db_state or user_desired_state_update' unless workspace

      # Handle agent updates
      # noinspection RubyResolve
      agent_actual_state_updates.each_with_index do |actual_state_update_fixture_args, response_expectations_index|
        update_type = RemoteDevelopment::Workspaces::Reconcile::UpdateType::PARTIAL
        deployment_resource_version_from_agent ||= initial_resource_version

        workspace_agent_infos =
          if actual_state_update_fixture_args
            previous_actual_state = actual_state_update_fixture_args[0].to_s.camelize
            current_actual_state = actual_state_update_fixture_args[1].to_s.camelize
            workspace_exists = actual_state_update_fixture_args[2]
            deployment_resource_version_from_agent = (deployment_resource_version_from_agent.to_i + 1).to_s
            [
              create_workspace_agent_info(
                workspace_id: workspace.id,
                workspace_name: workspace.name,
                workspace_namespace: workspace.namespace,
                agent_id: workspace.agent.id,
                owning_inventory: "#{workspace.name}-workspace-inventory",
                resource_version: deployment_resource_version_from_agent,
                current_actual_state: current_actual_state,
                previous_actual_state: previous_actual_state,
                workspace_exists: workspace_exists,
                user_name: user.name,
                user_email: user.email
              )
            ]
          else
            []
          end

        result = described_class.new.process(
          agent: workspace.agent,
          workspace_agent_infos: workspace_agent_infos,
          update_type: update_type
        )
        workspace_rails_infos = result[0].fetch(:workspace_rails_infos)

        # assert on the rails_info response to the agent
        expect(workspace_rails_infos.size).to eq(1)
        response_expectation = response_expectations[response_expectations_index]
        # assert on the config_to_apply presence
        expected_config_to_apply_present = response_expectation[0]
        expect(workspace_rails_infos[0].fetch(:config_to_apply).present?).to eq(expected_config_to_apply_present)
        # assert on the deployment_resource_version presence/value
        expected_deployment_resource_version =
          response_expectation[1] ? deployment_resource_version_from_agent : nil
        deployment_resource_version = workspace_rails_infos[0].fetch(:deployment_resource_version)
        expect(deployment_resource_version).to eq(expected_deployment_resource_version)

        # assert on the workspace state in the db after processing the agent update
        expect(workspace.reload.slice(:desired_state, :actual_state).values)
          .to eq(db_expectations[db_expectation_index].map(&:to_s).map(&:camelize))
        db_expectation_index += 1
      end
    end
  end
end
