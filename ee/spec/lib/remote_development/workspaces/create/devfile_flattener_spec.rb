# frozen_string_literal: true

require "spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::DevfileFlattener, feature_category: :remote_development do
  include_context 'with remote development shared fixtures'

  let(:devfile_yaml) { example_devfile }
  let(:expected_processed_devfile) { YAML.safe_load(example_flattened_devfile) }
  let(:value) { { devfile_yaml: devfile_yaml } }

  subject do
    described_class.flatten(value)
  end

  it "merges flattened devfile to passed value" do
    expect(subject).to eq(
      {
        devfile_yaml: devfile_yaml,
        processed_devfile: expected_processed_devfile
      }
    )
  end

  context "when devfile has no components" do
    let(:devfile_yaml) { read_devfile('example.no-components-devfile.yaml') }
    let(:expected_processed_devfile) do
      YAML.safe_load(read_devfile('example.no-components-flattened-devfile.yaml'))
    end

    it "adds an empty components entry" do
      expect(subject.fetch(:processed_devfile)).to eq(expected_processed_devfile)
    end
  end
end
