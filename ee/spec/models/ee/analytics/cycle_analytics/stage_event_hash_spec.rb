# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageEventHash, type: :model do
  let(:stage_event_hash) { described_class.create!(hash_sha256: hash_sha256) }
  let(:hash_sha256) { 'does_not_matter' }

  describe 'associations' do
    it { is_expected.to have_many(:cycle_analytics_group_stages) }
  end

  describe '.cleanup_if_unused' do
    it 'removes the record if there is no project or group stages with given stage events hash' do
      described_class.cleanup_if_unused(stage_event_hash.id)

      expect(described_class.find_by_id(stage_event_hash.id)).to be_nil
    end

    it 'does not remove the record if at least 1 group stage for the given stage events hash exists' do
      id = create(:cycle_analytics_stage).stage_event_hash_id

      described_class.cleanup_if_unused(id)

      expect(described_class.find_by_id(id)).not_to be_nil
    end
  end
end
