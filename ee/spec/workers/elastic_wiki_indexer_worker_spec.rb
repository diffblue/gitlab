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
            expect(ElasticDeleteProjectWorker).to receive(:perform_async).with(project.id, project.es_id)
            expect(Gitlab::Elastic::Indexer).not_to receive(:new)
            expect(logger_double).not_to receive(:info)
            expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
            expect(worker.perform(project.id, project.class.name)).to be true
          end
        end

        context 'when elasticsearch is enabled for Project' do
          context 'and options force is passed as true' do
            it 'does runs Gitlab::Elastic::Indexer with force and does performs logging and metrics' do
              expect_next_instance_of(Gitlab::Elastic::Indexer, project, { wiki: true, force: true }) do |indexer|
                expect(indexer).to receive(:run).and_return(true)
              end
              expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
              expect(logger_double).to receive(:info)
              expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_apdex)
              worker.perform(project.id, project.class.name, { force: true })
            end
          end

          context 'and options is not passed' do
            it 'does runs Gitlab::Elastic::Indexer without force and does performs logging and metrics' do
              expect_next_instance_of(Gitlab::Elastic::Indexer, project, { wiki: true, force: false }) do |indexer|
                expect(indexer).to receive(:run).and_return(true)
              end
              expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
              expect(logger_double).to receive(:info)
              expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_apdex)
              worker.perform(project.id, project.class.name)
            end
          end
        end
      end

      context 'when container is Group' do
        let_it_be(:group) { create(:group) }

        context 'when elasticsearch is disabled for Group' do
          it 'does not runs Gitlab::Elastic::Indexer and does not performs logging and metrics' do
            allow_next_found_instance_of(Group) do |group|
              expect(group).to receive(:use_elasticsearch?).and_return(false)
            end
            expect(Search::Wiki::ElasticDeleteGroupWikiWorker).to receive(:perform_async).with(group.id)
            expect(Gitlab::Elastic::Indexer).not_to receive(:new)
            expect(logger_double).not_to receive(:info)
            expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
            expect(worker.perform(group.id, group.class.name)).to be true
          end
        end

        context 'when elasticsearch is enabled for Group' do
          it 'does runs Gitlab::Elastic::Indexer and does performs logging and metrics' do
            allow_next_found_instance_of(Group) do |group|
              expect(group).to receive(:use_elasticsearch?).and_return(true)
            end
            expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
              expect(indexer).to receive(:run).and_return(true)
            end
            expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
            expect(logger_double).to receive(:info)
            expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_apdex)
            worker.perform(group.id, group.class.name)
          end
        end
      end

      context 'when container is neither Group nor Project' do
        let_it_be(:user) { create(:user) }

        it 'does not runs Gitlab::Elastic::Indexer, performs error logging and does not performs metrics log' do
          expect(Gitlab::Elastic::Indexer).not_to receive(:new)
          expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
          expect(logger_double).to receive(:error).with(container_id: user.id, container_type: user.class.name,
            message: 'ElasticWikiIndexerWorker only accepts Project and Group')
          expect(logger_double).not_to receive(:info)
          expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)
          expect(worker.perform(user.id, user.class.name)).to be true
        end
      end

      context 'when container can not be found' do
        it 'does not runs Gitlab::Elastic::Indexer and does not performs logging and metrics' do
          es_id = Gitlab::Elastic::Helper.build_es_id(es_type: project.class.es_type, target_id: 0)
          expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)
          expect(logger_double).to receive(:warn).with(container_id: 0, container_type: project.class.name,
            message: 'Container record not found')
          expect(ElasticDeleteProjectWorker).to receive(:perform_async).with(0, es_id)
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
