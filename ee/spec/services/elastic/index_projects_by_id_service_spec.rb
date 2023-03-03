# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::IndexProjectsByIdService, feature_category: :global_search do
  describe '#execute' do
    it 'schedules index workers' do
      project1 = create(:project)
      project2 = create(:project)

      expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project1, project2)

      Sidekiq::Testing.fake! do
        described_class.new.execute(project_ids: [project1.id, project2.id], namespace_ids: [3, 4])
      end

      jobs = Sidekiq::Queues.jobs_by_worker[ElasticNamespaceIndexerWorker.name]

      expect(jobs.size).to eq(2)
      expect(jobs[0]['args']).to eq([3, 'index'])
      expect(jobs[1]['args']).to eq([4, 'index'])
    end
  end
end
