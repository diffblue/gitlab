# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::UpdateEnvironmentService, feature_category: :continuous_delivery do
  include ::EE::GeoHelpers

  let(:primary) { create(:geo_node, :primary) }
  let(:project) { create(:project, :repository) }
  let(:repository_state) { create(:repository_state, :repository_verified, project: project) }
  let!(:deployment) { create(:deployment, :success, project: project) }

  before do
    stub_current_geo_node(primary)
  end

  subject { described_class.new(deployment) }

  describe '#execute' do
    it 'triggers a Geo event about the new deployment ref' do
      expect_next_instance_of(Geo::RepositoryUpdatedService) do |service|
        expect(service).to receive(:execute)
      end

      subject.execute
    end

    it 'resets the repository verification checksum' do
      expect { subject.execute }.to change { repository_state.reload.repository_verification_checksum }.to(nil)
    end

    it 'returns the deployment' do
      expect(subject.execute).to eq(deployment)
    end
  end
end
