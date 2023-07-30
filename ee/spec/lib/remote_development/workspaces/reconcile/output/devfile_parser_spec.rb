# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Output::DevfileParser, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:logger) { instance_double(Logger) }
  let(:user) { instance_double("User", name: "name", email: "name@example.com") }
  let(:agent) { instance_double("Clusters::Agent", id: 1) }
  let(:workspace) do
    instance_double(
      "RemoteDevelopment::Workspace",
      id: 1,
      name: "name",
      namespace: "namespace",
      deployment_resource_version: "1",
      desired_state: RemoteDevelopment::Workspaces::States::RUNNING,
      actual_state: RemoteDevelopment::Workspaces::States::STOPPED,
      dns_zone: "workspaces.localdev.me",
      processed_devfile: example_processed_devfile,
      user: user,
      agent: agent
    )
  end

  let(:owning_inventory) { "#{workspace.name}-workspace-inventory" }

  let(:domain_template) { "{{.port}}-#{workspace.name}.#{workspace.dns_zone}" }

  let(:expected_workspace_resources) do
    YAML.load_stream(
      create_config_to_apply(
        workspace_id: workspace.id,
        workspace_name: workspace.name,
        workspace_namespace: workspace.namespace,
        agent_id: workspace.agent.id,
        owning_inventory: owning_inventory,
        started: true,
        include_inventory: false,
        include_network_policy: false,
        user_name: user.name,
        user_email: user.email
      )
    )
  end

  subject do
    described_class
  end

  it 'returns workspace_resources' do
    workspace_resources = subject.get_all(
      processed_devfile: example_processed_devfile,
      name: workspace.name,
      namespace: workspace.namespace,
      replicas: 1,
      domain_template: domain_template,
      labels: { 'agent.gitlab.com/id' => workspace.agent.id },
      annotations: {
        'config.k8s.io/owning-inventory' => owning_inventory,
        'workspaces.gitlab.com/host-template' => domain_template,
        'workspaces.gitlab.com/id' => workspace.id
      },
      user: user,
      logger: logger
    )

    expect(workspace_resources).to eq(expected_workspace_resources)
  end

  context "when Devfile::CliError is raised" do
    before do
      allow(Devfile::Parser).to receive(:get_all).and_raise(Devfile::CliError.new("some error"))
    end

    it "logs the error" do
      expect(logger).to receive(:warn).with(
        message: 'Error parsing devfile with Devfile::Parser.get_all',
        error_type: 'reconcile_devfile_parser_error',
        workspace_name: workspace.name,
        workspace_namespace: workspace.namespace,
        devfile_parser_error: "some error"
      )

      workspace_resources = subject.get_all(
        processed_devfile: "",
        name: workspace.name,
        namespace: workspace.namespace,
        replicas: 1,
        domain_template: "",
        labels: {},
        annotations: {},
        user: user,
        logger: logger
      )

      expect(workspace_resources).to eq([])
    end
  end
end
