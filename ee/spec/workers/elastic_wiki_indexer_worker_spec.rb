# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticWikiIndexerWorker, feature_category: :global_search do
  describe '#perform' do
    subject(:worker) { described_class.new }

    let(:logger_double) { instance_double(Gitlab::Elasticsearch::Logger) }
    let_it_be(:project) { create(:project, :repository) }

    context 'when ES is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'does not runs Gitlab::Elastic::Indexer and does not performs logging and metrics' do
        expect(Gitlab::Elastic::Indexer).not_to receive(:new)
        expect(logger_double).not_to receive(:info)
        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        expect(worker.perform(project.id, project.class.name)).to be true
      end
    end

    context 'when ES is enabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: true)
      end

      context 'when container is Project' do
        context 'when elasticsearch is disabled for Project' do
          it 'does not runs Gitlab::Elastic::Indexer and does not performs logging and metrics' do
            allow_next_found_instance_of(Project) do |project|
              expect(project).to receive(:use_elasticsearch?).and_return(false)
            end
            expect(Gitlab::Elastic::Indexer).not_to receive(:new)
            expect(logger_double).not_to receive(:info)
            expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
            expect(worker.perform(project.id, project.class.name)).to be true
          end
        end

        context 'when elasticsearch is enabled for Project' do
          it 'does runs Gitlab::Elastic::Indexer and does performs logging and metrics' do
            expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
              expect(indexer).to receive(:run).and_return(true)
            end
            expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
            expect(logger_double).to receive(:info)
            expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_apdex)
            worker.perform(project.id, project.class.name)
          end
        end
      end

      context 'when container is Group' do
        let_it_be(:group) { create(:group) }

        it 'does not runs Gitlab::Elastic::Indexer, performs error logging and does not performs metrics log' do
          allow_next_found_instance_of(Group) do |group|
            expect(group).to receive(:use_elasticsearch?).and_return(true)
          end
          expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
          expect(logger_double).to receive(:error).with(message: 'ElasticWikiIndexerWorker only accepts Project',
            container_id: group.id, container_type: group.class.name)
          expect(Gitlab::Elastic::Indexer).not_to receive(:new)
          expect(logger_double).not_to receive(:info)
          expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
          expect(worker.perform(group.id, group.class.name)).to be true
        end
      end

      context 'when container can not be found' do
        it 'does not runs Gitlab::Elastic::Indexer and does not performs logging and metrics' do
          expect(Gitlab::Elastic::Indexer).not_to receive(:new)
          expect(logger_double).not_to receive(:info)
          expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
          expect(worker.perform(0, project.class.name)).to be true
        end
      end

      context 'when container_id is nil' do
        it 'does not runs Gitlab::Elastic::Indexer, performs error logging and does not performs metrics log' do
          expect(Gitlab::Elastic::Indexer).not_to receive(:new)
          expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
          expect(logger_double).to receive(:error).with(message: 'container_id or container_type can not be nil',
            container_id: nil, container_type: project.class.name)
          expect(logger_double).not_to receive(:info)
          expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
          expect(worker.perform(nil, project.class.name)).to be true
        end
      end
    end
  end
end
