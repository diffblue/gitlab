# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticClusterReindexingCronWorker, feature_category: :global_search do
  subject { described_class.new }

  describe '#perform' do
    it 'calls execute method' do
      expect(Elastic::ReindexingTask).to receive(:current).and_return(build(:elastic_reindexing_task))

      expect_next_instance_of(Elastic::ClusterReindexingService) do |service|
        expect(service).to receive(:execute).and_return(false)
      end

      subject.perform
    end

    it 'removes old indices if no task is found' do
      expect(Elastic::ReindexingTask).to receive(:current).and_return(nil)
      expect(Elastic::ReindexingTask).to receive(:drop_old_indices!)

      expect(subject.perform).to eq(false)
    end
  end
end
