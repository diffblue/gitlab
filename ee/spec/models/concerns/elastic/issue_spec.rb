# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue, :elastic, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  let(:project) { create :project, :public }
  let(:admin) { create :user, :admin }

  context 'when limited indexing is on' do
    let_it_be(:project) { create :project, name: 'test1' }
    let_it_be(:issue) { create :issue, project: project }

    before do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)
    end

    context 'when the project is not enabled specifically' do
      describe '#searchable?' do
        it 'returns false' do
          expect(issue.searchable?).to be_falsey
        end
      end
    end

    context 'when a project is enabled specifically' do
      before do
        create :elasticsearch_indexed_project, project: project
      end

      describe '#searchable?' do
        it 'returns true' do
          expect(issue.searchable?).to be_truthy
        end
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
          issue = create :issue, project: project

          expect(issue.searchable?).to be_truthy
        end
      end
    end
  end

  it "searches issues", :aggregate_failures do
    Sidekiq::Testing.inline! do
      create :issue, title: 'bla-bla term1', project: project
      create :issue, description: 'bla-bla term2', project: project
      create :issue, project: project

      # The issue I have no access to except as an administrator
      create :issue, title: 'bla-bla term3', project: create(:project, :private)

      ensure_elasticsearch_index!
    end

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('(term1 | term2 | term3) +bla-bla', options: options).total_count).to eq(2)
    expect(described_class.elastic_search(described_class.last.to_reference, options: options).total_count).to eq(1)
    expect(described_class.elastic_search('bla-bla', options: { project_ids: :any, public_and_internal_projects: true }).total_count).to eq(3)
  end

  it "names elasticsearch queries" do
    described_class.elastic_search('*').total_count

    assert_named_queries('issue:match:search_terms', 'issue:authorized:project')
  end

  it "searches by iid and scopes to type: issue only" do
    issue = nil

    Sidekiq::Testing.inline! do
      issue = create :issue, title: 'bla-bla issue', project: project
      create :issue, description: 'term2 in description', project: project

      # MergeRequest with the same iid should not be found in Issue search
      create :merge_request, title: 'bla-bla', source_project: project, iid: issue.iid

      ensure_elasticsearch_index!
    end

    # User needs to be admin or the MergeRequest would just be filtered by
    # confidential: false
    options = { project_ids: [project.id], current_user: admin }

    results = described_class.elastic_search("##{issue.iid}", options: options)
    expect(results.total_count).to eq(1)
    expect(results.first.title).to eq('bla-bla issue')
  end

  context 'json' do
    let_it_be(:assignee) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, :internal, namespace: subgroup) }
    let_it_be(:label) { create(:label) }
    let_it_be(:issue) { create(:labeled_issue, project: project, assignees: [assignee], labels: [label]) }
    let_it_be(:award_emoji) { create(:award_emoji, :upvote, awardable: issue) }
    let(:expected_hash) do
      issue.attributes.extract!(
        'id',
        'iid',
        'title',
        'description',
        'created_at',
        'updated_at',
        'project_id',
        'author_id',
        'confidential'
      ).merge({
              'type' => issue.es_type,
              'state' => issue.state,
              'upvotes' => 1,
              'namespace_ancestry_ids' => "#{group.id}-#{subgroup.id}-",
              'label_ids' => [label.id.to_s],
              'schema_version' => 23_03,
              'assignee_id' => [assignee.id],
              'issues_access_level' => ProjectFeature::ENABLED,
              'visibility_level' => Gitlab::VisibilityLevel::INTERNAL,
              'hashed_root_namespace_id' => issue.project.namespace.hashed_root_namespace_id
            })
    end

    it 'returns json with all needed elements' do
      set_elasticsearch_migration_to :add_hashed_root_namespace_id_to_issues, including: true
      expected_hash['hidden'] = issue.hidden?
      expect(issue.__elasticsearch__.as_indexed_json).to eq(expected_hash)
    end

    it 'does not have an N+1' do
      set_elasticsearch_migration_to :add_hashed_root_namespace_id_to_issues, including: true

      control = ActiveRecord::QueryRecorder.new do
        issue.__elasticsearch__.as_indexed_json
      end

      group_with_parent = create(:group, parent: create(:group))
      issue.project.namespace.update!(parent_id: group_with_parent.id)

      expect do
        issue.__elasticsearch__.as_indexed_json
      end.not_to exceed_query_limit(control.count)
    end
  end

  it 'handles a project missing project_feature', :aggregate_failures do
    issue = create :issue, project: project
    allow(issue.project).to receive(:project_feature).and_return(nil)

    expect { issue.__elasticsearch__.as_indexed_json }.not_to raise_error
    expect(issue.__elasticsearch__.as_indexed_json['issues_access_level']).to eq(ProjectFeature::PRIVATE)
  end

  context 'field length limits' do
    context 'when there is an elasticsearch_indexed_field_length limit' do
      it 'truncates to the default plan limit' do
        stub_ee_application_setting(elasticsearch_indexed_field_length_limit: 10)

        issue = create :issue, description: 'The description is too long'

        indexed_json = issue.__elasticsearch__.as_indexed_json

        expect(indexed_json['description']).to eq('The descri')
      end
    end

    context 'when the elasticsearch_indexed_field_length limit is 0' do
      it 'does not truncate the fields' do
        stub_ee_application_setting(elasticsearch_indexed_field_length_limit: 0)

        issue = create :issue, description: 'The description is too long'

        indexed_json = issue.__elasticsearch__.as_indexed_json

        expect(indexed_json['description']).to eq('The description is too long')
      end
    end
  end

  context 'when hashed root namespace id issues migration has not been finished' do
    let_it_be(:issue) { create(:issue) }

    before do
      set_elasticsearch_migration_to(:add_hashed_root_namespace_id_to_issues, including: false)
    end

    it 'does not include hashed_root_namespace_id' do
      payload = issue.__elasticsearch__.as_indexed_json

      expect(payload).not_to include('hashed_root_namespace_id')
    end
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:record1) { create(:issue, project: project, title: 'test-issue') }
    let(:record2) { create(:issue, project: project2, title: 'test-issue') }
  end
end
