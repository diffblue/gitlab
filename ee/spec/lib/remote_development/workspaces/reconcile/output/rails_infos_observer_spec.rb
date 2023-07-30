# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Output::RailsInfosObserver, feature_category: :remote_development do
  let(:agent) { instance_double("Clusters::Agent", id: 1) }
  let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::PARTIAL }
  let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
  let(:actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }
  let(:logger) { instance_double(::Logger) }

  let(:workspace_rails_infos) do
    [
      {
        name: "workspace1",
        namespace: "namespace1",
        deployment_resource_version: "1",
        desired_state: desired_state,
        actual_state: actual_state,
        config_to_apply: :does_not_matter_should_not_be_logged
      },
      {
        name: "workspace2",
        namespace: "namespace2",
        deployment_resource_version: "2",
        desired_state: desired_state,
        actual_state: actual_state,
        config_to_apply: :does_not_matter_should_not_be_logged
      }
    ]
  end

  let(:expected_logged_workspace_rails_infos) do
    [
      {
        name: "workspace1",
        namespace: "namespace1",
        deployment_resource_version: "1",
        desired_state: desired_state,
        actual_state: actual_state
      },
      {
        name: "workspace2",
        namespace: "namespace2",
        deployment_resource_version: "2",
        desired_state: desired_state,
        actual_state: actual_state
      }
    ]
  end

  let(:value) do
    {
      agent: agent,
      update_type: update_type,
      workspace_rails_infos: workspace_rails_infos,
      logger: logger
    }
  end

  subject do
    described_class.observe(value)
  end

  it "logs workspace_rails_infos", :unlimited_max_formatted_output_length do
    expect(logger).to receive(:debug).with(
      message: 'Returning workspace_rails_infos',
      agent_id: agent.id,
      update_type: update_type,
      count: workspace_rails_infos.length,
      workspace_rails_infos: expected_logged_workspace_rails_infos
    )

    expect(subject).to eq(value)
  end
end
