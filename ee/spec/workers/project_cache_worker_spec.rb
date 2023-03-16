# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCacheWorker, feature_category: :projects do
  let_it_be(:project) { create(:project, :repository) }

  let(:worker) { described_class.new }

  describe '#perform' do
    context 'with an existing project' do
      context 'when in Geo secondary node' do
        before do
          allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
        end

        it 'updates only non database cache' do
          expect(worker).to receive(:perform_geo_secondary).and_call_original
          expect_any_instance_of(Repository).to receive(:refresh_method_caches)
            .and_call_original

          expect_any_instance_of(Project).not_to receive(:update_repository_size)
          expect_any_instance_of(Project).not_to receive(:update_commit_count)

          worker.perform(project.id, %w(readme))
        end

        it 'is idempotent' do
          expect { perform_multiple([project.id, %w(readme)]) }.not_to raise_error
        end
      end
    end
  end
end
