# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::ProjectClonerComponentInjector, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let_it_be(:group) { create(:group, name: "test-group") }
  let_it_be(:project) do
    create(:project, :public, :in_group, :repository, path: "test-project", namespace: group)
  end

  let(:flattened_devfile_name) { 'example.flattened-devfile.yaml' }
  let(:processed_devfile) { YAML.safe_load(read_devfile(flattened_devfile_name)) }
  let(:expected_processed_devfile) { YAML.safe_load(example_processed_devfile) }
  let(:component_name) { "gl-cloner-injector" }
  let(:volume_name) { "gl-workspace-data" }
  let(:value) do
    {
      params: {
        project: project
      },
      processed_devfile: processed_devfile,
      volume_mounts: {
        data_volume: {
          name: volume_name,
          path: "/projects"
        }
      }
    }
  end

  subject do
    described_class.inject(value)
  end

  it "injects the project cloner component" do
    components = subject.dig(:processed_devfile, "components")
    project_cloner_component = components.find { |component| component.fetch("name") == component_name }
    expected_components = expected_processed_devfile.fetch("components")
    expected_volume_component = expected_components.find do |component|
      component.fetch("name") == component_name
    end
    expect(project_cloner_component).to eq(expected_volume_component)
  end
end
