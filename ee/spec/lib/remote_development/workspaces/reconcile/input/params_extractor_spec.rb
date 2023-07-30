# frozen_string_literal: true

require_relative '../../../fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::Input::ParamsExtractor, feature_category: :remote_development do
  let(:agent) { instance_double("Clusters::Agent") }
  let(:original_params) do
    {
      "update_type" => "full",
      "workspace_agent_infos" => [
        {
          "name" => "my-workspace",
          "actual_state" => "unknown"
        }
      ]
    }
  end

  let(:value) do
    {
      agent: agent,
      original_params: original_params,
      existing_symbol_key_entry: "entry1",
      existing_string_key_entry: "entry2"
    }
  end

  subject do
    described_class.extract(value)
  end

  it "extracts and flattens agent and params contents to top level and deep symbolizes keys" do
    expect(subject).to eq(
      {
        agent: agent,
        update_type: "full",
        original_params: original_params,
        workspace_agent_info_hashes_from_params: [
          {
            name: "my-workspace",
            actual_state: "unknown"
          }
        ],
        existing_symbol_key_entry: "entry1",
        existing_string_key_entry: "entry2"
      }
    )
  end
end
