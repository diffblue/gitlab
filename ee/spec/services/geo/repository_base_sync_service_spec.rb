# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryBaseSyncService, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  let(:project) { build('project') }
  let(:repository) { project.repository }

  let_it_be(:geo_primary) { create(:geo_node, :primary) }
  let_it_be(:geo_secondary) { create(:geo_node, :secondary) }

  before do
    stub_current_geo_node(geo_secondary)
  end

  subject { described_class.new(project) }

  describe '#lease_key' do
    it 'returns a key in the correct pattern' do
      allow(described_class).to receive(:type) { :wiki }
      allow(project).to receive(:id) { 999 }

      expect(subject.lease_key).to eq('geo_sync_service:wiki:999')
    end
  end

  describe '#lease_timeout' do
    it 'returns a lease timeout value' do
      expect(subject.lease_timeout).to eq(8.hours)
    end
  end

  describe '#repository' do
    it 'raises a NotImplementedError' do
      expect { subject.repository }.to raise_error(NotImplementedError)
    end
  end

  context 'with a repository defined' do
    before do
      allow(subject).to receive(:repository) { repository }
    end

    describe '#fetch_geo_mirror' do
      it 'delegates to repository#fetch_as_mirror' do
        expect(repository).to receive(:fetch_as_mirror)

        subject.send(:fetch_geo_mirror)
      end
    end

    describe '#clone_geo_mirror' do
      it 'delegates to repository#clone_as_mirror' do
        expect(repository).to receive(:clone_as_mirror)

        subject.send(:clone_geo_mirror)
      end
    end
  end
end
