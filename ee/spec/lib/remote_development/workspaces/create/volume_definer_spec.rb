# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe RemoteDevelopment::Workspaces::Create::VolumeDefiner, feature_category: :remote_development do
  let(:value) { { params: 1 } }

  subject do
    described_class.define(value)
  end

  it "merges volume mount info to passed value" do
    expect(subject).to eq(
      {
        params: 1,
        volume_mounts: {
          data_volume: {
            name: "gl-workspace-data",
            path: "/projects"
          }
        }
      }
    )
  end
end
