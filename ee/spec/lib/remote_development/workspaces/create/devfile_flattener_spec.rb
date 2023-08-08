# frozen_string_literal: true

require_relative "../../fast_spec_helper"

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
      Result.ok(
        {
          devfile_yaml: devfile_yaml,
          processed_devfile: expected_processed_devfile
        }
      )
    )
  end

  context "when devfile has no components" do
    let(:devfile_yaml) { read_devfile('example.no-components-devfile.yaml') }
    let(:expected_processed_devfile) do
      YAML.safe_load(read_devfile('example.no-components-flattened-devfile.yaml'))
    end

    it "adds an empty components entry" do
      expect(subject).to eq(
        Result.ok(
          {
            devfile_yaml: devfile_yaml,
            processed_devfile: expected_processed_devfile
          }
        )
      )
    end
  end

  context "when flatten raises a Devfile::CliError" do
    let(:devfile_yaml) { read_devfile('example.invalid-extra-field-devfile.yaml') }

    it "returns the error message from the CLI" do
      expected_error_message =
        "failed to populateAndParseDevfile: invalid devfile schema. errors :\n" \
        "- (root): Additional property random is not allowed\n"
      message = subject.unwrap_err
      expect(message).to be_a(RemoteDevelopment::Messages::WorkspaceCreateDevfileFlattenFailed)
      expect(message.context).to eq(details: expected_error_message)
    end
  end
end
