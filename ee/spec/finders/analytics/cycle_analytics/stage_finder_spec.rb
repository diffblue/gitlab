# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageFinder do
  let_it_be(:group) { create(:group) }

  let(:stage_id) { { id: Gitlab::Analytics::CycleAnalytics::DefaultStages.names.first } }

  subject { described_class.new(parent: group, stage_id: stage_id[:id]).execute }

  context 'when looking up in-memory default stage by name exists' do
    it { expect(subject).not_to be_persisted }
    it { expect(subject.name).to eq(stage_id[:id]) }
  end

  context 'when in-memory default stage cannot be found' do
    before do
      stage_id[:id] = 'unknown_default_stage'
    end

    it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
  end

  context 'when persisted stage exists' do
    let(:stage) { create(:cycle_analytics_group_stage, namespace: group) }

    before do
      stage_id[:id] = stage.id
    end

    it { expect(subject).to be_persisted }
    it { expect(subject.name).to eq(stage.name) }
  end

  context 'when persisted stage cannot be found' do
    before do
      stage_id[:id] = -1
    end

    it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
  end
end
