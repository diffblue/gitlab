# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::VolumeComponentInjector, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:flattened_devfile_name) { 'example.flattened-devfile.yaml' }
  let(:processed_devfile) { YAML.safe_load(read_devfile(flattened_devfile_name)).to_h }
  let(:expected_processed_devfile) { YAML.safe_load(example_processed_devfile) }
  let(:component_name) { "gl-workspace-data" }
  let(:volume_name) { "gl-workspace-data" }
  let(:value) do
    {
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

  it "injects the workspace volume component" do
    components = subject.dig(:processed_devfile, "components")
    volume_component = components.find { |component| component.fetch("name") == component_name }
    expected_components = expected_processed_devfile.fetch("components")
    expected_volume_component = expected_components.find do |component|
      component.fetch("name") == component_name
    end
    expect(volume_component).to eq(expected_volume_component)
  end
end
