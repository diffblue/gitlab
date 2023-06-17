# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::RepositoryDestroyWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { project.id }
    end

    it 'destroy repository' do
      expect_next_instance_of(::Repositories::DestroyService) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform(project.id)
    end

    context 'when project does not exist' do
      it 'does not destroy repository' do
        expect(::Repositories::DestroyService).not_to receive(:new)

        worker.perform(non_existing_record_id)
      end
    end
  end
end
