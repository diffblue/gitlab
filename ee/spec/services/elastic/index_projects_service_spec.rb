# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::IndexProjectsService, feature_category: :global_search do
  describe '#execute' do
    context 'when elasticsearch_limit_indexing? is true' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
        create(:elasticsearch_indexed_project)
        create(:elasticsearch_indexed_namespace)
      end

      it 'schedules indexing for selected projects and namespaces' do
        expect_next_instance_of(::Elastic::IndexProjectsByIdService) do |service|
          expect(service).to receive(:execute).with(
            project_ids: ElasticsearchIndexedProject.target_ids,
            namespace_ids: ElasticsearchIndexedNamespace.target_ids
          )
        end

        subject.execute
      end
    end

    context 'when elasticsearch_limit_indexing? is false' do
      before do
        stub_ee_application_setting(elasticsearch_limit_indexing: false)
      end

      it 'schedules indexing for all projects' do
        expect_next_instance_of(::Elastic::IndexProjectsByRangeService) do |service|
          expect(service).to receive(:execute)
        end

        subject.execute
      end
    end
  end
end
