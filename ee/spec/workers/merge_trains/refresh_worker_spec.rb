# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::RefreshWorker, feature_category: :merge_trains do
  let(:worker) { described_class.new }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has an option to reschedule once if deduplicated' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once })
  end

  describe '#perform' do
    subject { worker.perform(target_project_id, target_branch) }

    let(:project) { create(:project) }
    let(:target_project_id) { project.id }
    let(:target_branch) { 'master' }

    include_examples 'an idempotent worker' do
      let(:job_args) { [target_project_id, target_branch] }
    end
  end
end
