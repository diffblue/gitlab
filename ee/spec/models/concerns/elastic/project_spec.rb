# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Project, :elastic, :clean_gitlab_redis_shared_state, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'when limited indexing is on' do
    let_it_be(:project) { create :project, name: 'main_project' }

    before do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)
    end

    context 'when the project is not enabled specifically' do
      describe '#searchable?' do
        it 'returns false' do
          expect(project.searchable?).to be_falsey
        end
      end

      describe '#use_elasticsearch?' do
        it 'returns false' do
          expect(project.use_elasticsearch?).to be_falsey
        end
      end
    end

    context 'when a project is enabled specifically' do
      before do
        create :elasticsearch_indexed_project, project: project
      end

      describe '#searchable?' do
        it 'returns true' do
          expect(project.searchable?).to be_truthy
        end
      end

      describe '#use_elasticsearch?' do
        it 'returns true' do
          expect(project.use_elasticsearch?).to be_truthy
        end
      end

      it 'only indexes enabled projects' do
        Sidekiq::Testing.inline! do
          create :project, path: 'test_two', description: 'awesome project'
          create :project

          ensure_elasticsearch_index!
        end

        expect(described_class.elastic_search('main_pro*', options: { project_ids: :any }).total_count).to eq(1)
        expect(described_class.elastic_search('"test_two"', options: { project_ids: :any }).total_count).to eq(0)
      end
    end

    context 'when a group is enabled' do
      let_it_be(:group) { create(:group) }

      before do
        create :elasticsearch_indexed_namespace, namespace: group
      end

      describe '#searchable?' do
        it 'returns true' do
          project = create :project, name: 'test1', group: group

          expect(project.searchable?).to be_truthy
        end
      end

      it 'indexes only projects under the group' do
        Sidekiq::Testing.inline! do
          create :project, name: 'group_test1', group: create(:group, parent: group)
          create :project, name: 'group_test2', description: 'awesome project'
          create :project, name: 'group_test3', group: group
          create :project, path: 'someone_elses_project', name: 'test4'

          ensure_elasticsearch_index!
        end

        expect(described_class.elastic_search('group_test*', options: { project_ids: :any }).total_count).to eq(2)
        expect(described_class.elastic_search('"group_test3"', options: { project_ids: :any }).total_count).to eq(1)
        expect(described_class.elastic_search('"group_test2"', options: { project_ids: :any }).total_count).to eq(0)
        expect(described_class.elastic_search('"group_test4"', options: { project_ids: :any }).total_count).to eq(0)
      end

      context 'default_operator' do
        RSpec.shared_examples 'use correct default_operator' do |operator|
          before do
            Sidekiq::Testing.inline! do
              create :project, name: 'project1', group: group, description: 'test foo'
              create :project, name: 'project2', group: group, description: 'test'
              create :project, name: 'project3', group: group, description: 'foo'

              ensure_elasticsearch_index!
            end
          end

          it 'uses correct operator' do
            count_for_or = described_class.elastic_search('test | foo', options: { project_ids: :any }).total_count
            expect(count_for_or).to be > 0

            count_for_and = described_class.elastic_search('test + foo', options: { project_ids: :any }).total_count
            expect(count_for_and).to be > 0

            expect(count_for_or).not_to be equal(count_for_and)

            expected_count = case operator
                             when :or
                               count_for_or
                             when :and
                               count_for_and
                             else
                               raise ArgumentError, 'Invalid operator'
                             end

            expect(described_class.elastic_search('test foo', options: { project_ids: :any }).total_count).to eq(expected_count)
          end
        end

        context 'feature flag is enabled' do
          before do
            stub_feature_flags(elasticsearch_use_or_default_operator: true)
          end

          include_examples 'use correct default_operator', :or
        end

        context 'feature flag is disabled' do
          before do
            stub_feature_flags(elasticsearch_use_or_default_operator: false)
          end

          include_examples 'use correct default_operator', :and
        end
      end
    end
  end

  # This test is added to address the issues described in
  context 'when projects and snippets co-exist', :elastic_clean, issue: 'https://gitlab.com/gitlab-org/gitlab/issues/36340' do
    before do
      create :project
      create :snippet, :public
    end

    context 'when searching with a wildcard' do
      it 'only returns projects', :sidekiq_inline do
        ensure_elasticsearch_index!
        response = described_class.elastic_search('*')

        expect(response.total_count).to eq(1)
        expect(response.results.first['_source']['type']).to eq(Project.es_type)
      end
    end
  end

  it "finds projects" do
    project_ids = []

    Sidekiq::Testing.inline! do
      project = create :project, name: 'test1'
      project1 = create :project, path: 'test2', description: 'awesome project'
      project2 = create :project
      create :project, path: 'someone_elses_project'
      project_ids += [project.id, project1.id, project2.id]

      # The project you have no access to except as an administrator
      create :project, :private, name: 'test3'

      ensure_elasticsearch_index!
    end

    expect(described_class.elastic_search('"test1"', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('"test2"', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('"awesome"', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('test*', options: { project_ids: project_ids }).total_count).to eq(2)
    expect(described_class.elastic_search('test*', options: { project_ids: :any }).total_count).to eq(3)
    expect(described_class.elastic_search('"someone_elses_project"', options: { project_ids: project_ids }).total_count).to eq(0)
  end

  it 'does not update Elasticsearch if pending_delete is true' do
    expect(Elastic::ProcessInitialBookkeepingService).to receive(:track!)
    project = create(:project)

    expect(Elastic::ProcessBookkeepingService).to receive(:track!)
    project.update!(name: 'test 1')

    expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)
    project.update!(pending_delete: true)
  end

  it "finds partial matches in project names" do
    project_ids = []

    Sidekiq::Testing.inline! do
      project = create :project, name: 'tesla-model-s'
      project1 = create :project, name: 'tesla_model_s'
      project_ids += [project.id, project1.id]

      ensure_elasticsearch_index!
    end

    expect(described_class.elastic_search('tesla', options: { project_ids: project_ids }).total_count).to eq(2)
  end

  it "names elasticsearch queries" do
    described_class.elastic_search('*').total_count

    assert_named_queries('doc:is_a:project', 'project:match:search_terms')
  end

  describe '.as_indexed_json' do
    let_it_be(:project) { create(:project) }

    it 'returns json with all needed elements' do
      expected_hash = project.attributes.extract!(
        'id',
        'name',
        'path',
        'description',
        'namespace_id',
        'created_at',
        'archived',
        'updated_at',
        'visibility_level',
        'last_activity_at'
      ).merge({
        'join_field' => project.es_type,
        'type' => project.es_type,
        'schema_version' => 2301,
        'traversal_ids' => project.elastic_namespace_ancestry,
        'name_with_namespace' => project.full_name,
        'path_with_namespace' => project.full_path
      })

      expected_hash.merge!(
        project.project_feature.attributes.extract!(
          'issues_access_level',
          'merge_requests_access_level',
          'snippets_access_level',
          'wiki_access_level',
          'repository_access_level'
        )
      )

      expect(project.__elasticsearch__.as_indexed_json).to eq(expected_hash)
    end
  end
end
