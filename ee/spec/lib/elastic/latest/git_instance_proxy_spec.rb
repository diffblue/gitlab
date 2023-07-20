# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::GitInstanceProxy, feature_category: :global_search do
  let(:project) { create(:project, :repository) }
  let(:included_class) { Elastic::Latest::RepositoryInstanceProxy }

  subject { included_class.new(project.repository) }

  describe '.methods_for_all_write_targets' do
    it 'contains extra method' do
      expect(included_class.methods_for_all_write_targets).to contain_exactly(
        *Elastic::Latest::ApplicationInstanceProxy.methods_for_all_write_targets,
        :delete_index_for_commits_and_blobs
      )
    end
  end

  describe '#es_parent' do
    context 'for wiki is false' do
      it 'contains project id' do
        expect(included_class.new(project.repository).es_parent).to eq("project_#{project.id}")
      end
    end

    context 'for wiki is true' do
      include ElasticsearchHelpers
      context 'when migration reindex_wikis_to_fix_routing is finished' do
        before do
          set_elasticsearch_migration_to(:reindex_wikis_to_fix_routing, including: true)
        end

        context 'for ProjectWiki repository' do
          it "contains project's root ancestor id" do
            repository = project.wiki.repository
            expect(included_class.new(repository).es_parent(true)).to eq "n_#{project.root_ancestor.id}"
          end
        end

        context 'for GroupWiki repository' do
          let_it_be(:group) { create :group }

          it "contains group's root ancestor id" do
            expect(included_class.new(group.wiki.repository).es_parent(true)).to eq "n_#{group.root_ancestor.id}"
          end
        end
      end

      context 'when migration reindex_wikis_to_fix_routing is not finished' do
        before do
          set_elasticsearch_migration_to(:reindex_wikis_to_fix_routing, including: false)
        end

        context 'for ProjectWiki repository' do
          it 'returns nil' do
            expect(included_class.new(project.wiki.repository).es_parent(true)).to be nil
          end
        end

        context 'for GroupWiki repository' do
          let_it_be(:group) { create :group }

          it 'returns nil' do
            expect(included_class.new(project.wiki.repository).es_parent(true)).to be nil
          end
        end
      end
    end
  end

  describe '#elastic_search' do
    let(:params) do
      {
        type: 'fake_type',
        page: 2,
        per: 30,
        options: { foo: :bar }
      }
    end

    it 'provides repository_id if not provided' do
      expected_params = params.deep_dup
      expected_params[:options][:repository_id] = project.id

      expect(subject.class).to receive(:elastic_search).with('foo', expected_params)

      subject.elastic_search('foo', **params)
    end

    it 'uses provided repository_id' do
      params[:options][:repository_id] = 42

      expect(subject.class).to receive(:elastic_search).with('foo', params)

      subject.elastic_search('foo', **params)
    end
  end

  describe '#elastic_search_as_found_blob' do
    let(:params) do
      {
        page: 2,
        per: 30,
        options: { foo: :bar },
        preload_method: nil
      }
    end

    it 'provides repository_id if not provided' do
      expected_params = params.deep_dup
      expected_params[:options][:repository_id] = project.id

      expect(subject.class).to receive(:elastic_search_as_found_blob).with('foo', expected_params)

      subject.elastic_search_as_found_blob('foo', **params)
    end

    it 'uses provided repository_id' do
      params[:options][:repository_id] = 42

      expect(subject.class).to receive(:elastic_search_as_found_blob).with('foo', params)

      subject.elastic_search_as_found_blob('foo', **params)
    end
  end

  describe '#blob_aggregations' do
    let(:options) do
      {
        project_ids: [project.id],
        public_and_internal_projects: false,
        order_by: nil,
        sort: nil
      }
    end

    it 'provides repository_id if not provided' do
      expected_params = options.deep_dup
      expected_params[:repository_id] = project.id

      expect(subject.class).to receive(:blob_aggregations).with('foo', expected_params)

      subject.blob_aggregations('foo', **options)
    end

    it 'uses provided repository_id' do
      options[:repository_id] = 42

      expect(subject.class).to receive(:blob_aggregations).with('foo', options)

      subject.blob_aggregations('foo', **options)
    end
  end

  describe '#delete_index_for_commits_and_blobs' do
    let(:write_targets) { [double(:write_target_1), double(:write_target_2)] }
    let(:read_target) { double(:read_target) }

    before do
      project.repository.__elasticsearch__.tap do |proxy|
        allow(proxy).to receive(:elastic_writing_targets).and_return(write_targets)
        allow(proxy).to receive(:elastic_reading_target).and_return(read_target)
      end
    end

    it 'is forwarded to all write targets' do
      expect(read_target).not_to receive(:delete_index_for_commits_and_blobs)
      expect(write_targets).to all(
        receive(:delete_index_for_commits_and_blobs).and_return({ '_shards' => {} })
      )

      project.repository.delete_index_for_commits_and_blobs
    end
  end
end
