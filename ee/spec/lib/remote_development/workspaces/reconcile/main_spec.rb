# frozen_string_literal: true

require_relative '../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Main, feature_category: :remote_development do
  include RemoteDevelopment::RailwayOrientedProgrammingHelpers

  let(:rails_infos) { [double] }
  let(:value) { { workspace_rails_infos: rails_infos } }
  let(:error_details) { 'some error details' }
  let(:err_message_context) { { details: error_details } }

  # rubocop:disable Layout/LineLength - keep all the class and method fixtures as single-liners easier scanning/editing
  # Classes

  let(:params_validator_class) { RemoteDevelopment::Workspaces::Reconcile::Input::ParamsValidator }
  let(:params_extractor_class) { RemoteDevelopment::Workspaces::Reconcile::Input::ParamsExtractor }
  let(:params_to_infos_converter_class) { RemoteDevelopment::Workspaces::Reconcile::Input::ParamsToInfosConverter }
  let(:agent_infos_observer_class) { RemoteDevelopment::Workspaces::Reconcile::Input::AgentInfosObserver }
  let(:workspaces_from_agent_infos_updater_class) { RemoteDevelopment::Workspaces::Reconcile::Persistence::WorkspacesFromAgentInfosUpdater }
  let(:orphaned_workspaces_observer_class) { RemoteDevelopment::Workspaces::Reconcile::Persistence::OrphanedWorkspacesObserver }
  let(:workspaces_to_be_returned_finder_class) { RemoteDevelopment::Workspaces::Reconcile::Persistence::WorkspacesToBeReturnedFinder }
  let(:workspaces_to_rails_infos_converter_class) { RemoteDevelopment::Workspaces::Reconcile::Output::WorkspacesToRailsInfosConverter }
  let(:workspaces_to_be_returned_updater_class) { RemoteDevelopment::Workspaces::Reconcile::Persistence::WorkspacesToBeReturnedUpdater }
  let(:rails_infos_observer_class) { RemoteDevelopment::Workspaces::Reconcile::Output::RailsInfosObserver }

  # Methods

  let(:params_validator_method) { params_validator_class.singleton_method(:validate) }
  let(:params_extractor_method) { params_extractor_class.singleton_method(:extract) }
  let(:params_to_infos_converter_method) { params_to_infos_converter_class.singleton_method(:convert) }
  let(:agent_infos_observer_method) { agent_infos_observer_class.singleton_method(:observe) }
  let(:workspaces_from_agent_infos_updater_method) { workspaces_from_agent_infos_updater_class.singleton_method(:update) }
  let(:orphaned_workspaces_observer_method) { orphaned_workspaces_observer_class.singleton_method(:observe) }
  let(:workspaces_to_be_returned_finder_method) { workspaces_to_be_returned_finder_class.singleton_method(:find) }
  let(:workspaces_to_rails_infos_converter_method) { workspaces_to_rails_infos_converter_class.singleton_method(:convert) }
  let(:workspaces_to_be_returned_updater_method) { workspaces_to_be_returned_updater_class.singleton_method(:update) }
  let(:rails_infos_observer_method) { rails_infos_observer_class.singleton_method(:observe) }
  # rubocop:enable Layout/LineLength

  # Subject

  subject(:response) { described_class.main(value) }

  before do
    allow(params_validator_class).to receive(:method) { params_validator_method }
    allow(params_extractor_class).to receive(:method) { params_extractor_method }
    allow(params_to_infos_converter_class).to receive(:method) { params_to_infos_converter_method }
    allow(agent_infos_observer_class).to receive(:method) { agent_infos_observer_method }
    allow(workspaces_from_agent_infos_updater_class).to receive(:method) { workspaces_from_agent_infos_updater_method }
    allow(orphaned_workspaces_observer_class).to receive(:method) { orphaned_workspaces_observer_method }
    allow(workspaces_to_be_returned_finder_class).to receive(:method) { workspaces_to_be_returned_finder_method }
    allow(workspaces_to_rails_infos_converter_class).to receive(:method) { workspaces_to_rails_infos_converter_method }
    allow(workspaces_to_be_returned_updater_class).to receive(:method) { workspaces_to_be_returned_updater_method }
    allow(rails_infos_observer_class).to receive(:method) { rails_infos_observer_method }
  end

  context 'when the ParamsValidator returns an err Result' do
    it 'returns an error response' do
      expect(params_validator_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::WorkspaceReconcileParamsValidationFailed.new)
      end
      expect(response)
        .to eq({ status: :error, message: 'Workspace reconcile params validation failed', reason: :bad_request })
    end
  end

  context 'when the ParamsValidator returns an ok Result' do
    before do
      stub_methods_to_return_ok_result(
        params_validator_method
      )

      stub_methods_to_return_value(
        params_extractor_method,
        params_to_infos_converter_method,
        agent_infos_observer_method,
        workspaces_from_agent_infos_updater_method,
        orphaned_workspaces_observer_method,
        workspaces_to_be_returned_finder_method,
        workspaces_to_rails_infos_converter_method,
        workspaces_to_be_returned_updater_method,
        rails_infos_observer_method
      )
    end

    it 'returns a workspace reconcile success response with the workspace as the payload' do
      expect(response).to eq({
        status: :success,
        payload: value
      })
    end
  end

  context 'when an invalid Result is returned' do
    it 'raises an UnmatchedResultError' do
      expect(params_validator_method).to receive(:call).with(value) do
        Result.err(RemoteDevelopment::Messages::WorkspaceReconcileSuccessful.new)
      end

      expect { response }.to raise_error(RemoteDevelopment::UnmatchedResultError)
    end
  end
end
