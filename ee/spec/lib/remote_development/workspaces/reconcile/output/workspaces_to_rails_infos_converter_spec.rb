# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Output::WorkspacesToRailsInfosConverter, feature_category: :remote_development do
  let(:logger) { instance_double(Logger) }
  let(:desired_state) { RemoteDevelopment::Workspaces::States::RUNNING }
  let(:actual_state) { RemoteDevelopment::Workspaces::States::STOPPED }
  let(:config_to_apply) { { foo: "bar" } }
  let(:config_to_apply_yaml) { "---\nfoo: bar\n" }
  let(:workspace1) do
    instance_double(
      "RemoteDevelopment::Workspace",
      id: 1,
      name: "workspace1",
      namespace: "namespace1",
      deployment_resource_version: "1",
      desired_state: desired_state,
      actual_state: actual_state
    )
  end

  let(:workspace2) do
    instance_double(
      "RemoteDevelopment::Workspace",
      id: 1,
      name: "workspace2",
      namespace: "namespace2",
      deployment_resource_version: "2",
      desired_state: desired_state,
      actual_state: actual_state
    )
  end

  let(:value) { { update_type: update_type, workspaces_to_be_returned: [workspace1, workspace2], logger: logger } }

  subject do
    described_class.convert(value)
  end

  before do
    allow(RemoteDevelopment::Workspaces::Reconcile::Output::DesiredConfigGenerator)
      .to receive(:generate_desired_config) { [config_to_apply] }
  end

  context "when update_type is FULL" do
    let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::FULL }

    it "merges workspace_rails_infos into value and includes config_to_apply" do
      expect(subject).to eq(
        value.merge(
          workspace_rails_infos: [
            {
              name: "workspace1",
              namespace: "namespace1",
              deployment_resource_version: "1",
              desired_state: desired_state,
              actual_state: actual_state,
              config_to_apply: config_to_apply_yaml
            },
            {
              name: "workspace2",
              namespace: "namespace2",
              deployment_resource_version: "2",
              desired_state: desired_state,
              actual_state: actual_state,
              config_to_apply: config_to_apply_yaml
            }
          ]
        )
      )
    end
  end

  context "when update_type is PARTIAL" do
    let(:update_type) { RemoteDevelopment::Workspaces::Reconcile::UpdateTypes::PARTIAL }

    before do
      allow(workspace1).to receive(:desired_state_updated_more_recently_than_last_response_to_agent?).and_return(true)
      allow(workspace2)
        .to receive(:desired_state_updated_more_recently_than_last_response_to_agent?).and_return(false)
    end

    context "when workspace.desired_state_updated_more_recently_than_last_response_to_agent == true" do
      it "includes config_to_apply" do
        expect(subject[:workspace_rails_infos][0][:config_to_apply]).to eq(config_to_apply_yaml)
      end
    end

    context "when workspace.desired_state_updated_more_recently_than_last_response_to_agent == false" do
      it "sets config_to_apply to nil" do
        expect(subject[:workspace_rails_infos][1][:config_to_apply]).to eq(nil)
      end
    end
  end
end
