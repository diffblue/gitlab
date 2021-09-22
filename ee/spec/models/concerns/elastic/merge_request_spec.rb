# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  let(:admin) { create(:user, :admin) }

  it_behaves_like 'limited indexing is enabled' do
    let_it_be(:object) { create :merge_request, source_project: project }
    let_it_be(:group) { create(:group) }
    let(:group_object) do
      project = create :project, name: 'test1', group: group
      create :merge_request, source_project: project
    end
  end

  it "searches merge requests", :sidekiq_might_not_need_inline do
    project = create :project, :public, :repository

    Sidekiq::Testing.inline! do
      create :merge_request, title: 'bla-bla term1', source_project: project
      create :merge_request, description: 'term2 in description', source_project: project, target_branch: "feature2"
      create :merge_request, source_project: project, target_branch: "feature3"

      # The merge request you have no access to except as an administrator
      create :merge_request, title: 'also with term3', source_project: create(:project, :private)

      ensure_elasticsearch_index!
    end

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('term1 | term2 | term3', options: options).total_count).to eq(2)
    expect(described_class.elastic_search(MergeRequest.last.to_reference, options: options).total_count).to eq(1)
    expect(described_class.elastic_search('term3', options: options).total_count).to eq(0)
    expect(described_class.elastic_search('term3', options: { project_ids: :any, public_and_internal_projects: true }).total_count).to eq(1)
  end

  it "names elasticsearch queries" do
    described_class.elastic_search('*').total_count

    assert_named_queries('doc:is_a:merge_request',
                         'merge_request:match:search_terms',
                         'merge_request:authorized:project')
  end

  it "searches by iid and scopes to type: merge_request only", :sidekiq_might_not_need_inline do
    project = create :project, :public, :repository
    merge_request = nil

    Sidekiq::Testing.inline! do
      merge_request = create :merge_request, title: 'bla-bla merge request', source_project: project
      create :merge_request, description: 'term2 in description', source_project: project, target_branch: "feature2"

      # Issue with the same iid should not be found in MergeRequest search
      create :issue, project: project, iid: merge_request.iid

      ensure_elasticsearch_index!
    end

    options = { project_ids: [project.id] }

    results = described_class.elastic_search("!#{merge_request.iid}", options: options)
    expect(results.total_count).to eq(1)
    expect(results.first.title).to eq('bla-bla merge request')
  end

  it "returns json with all needed elements" do
    merge_request = create :merge_request
    merge_request.project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)

    expected_hash = merge_request.attributes.extract!(
      'id',
      'iid',
      'target_branch',
      'source_branch',
      'title',
      'description',
      'created_at',
      'updated_at',
      'state',
      'merge_status',
      'source_project_id',
      'target_project_id',
      'author_id'
    ).merge({
      'state' => merge_request.state,
      'type' => merge_request.es_type,
      'merge_requests_access_level' => ProjectFeature::ENABLED,
      'visibility_level' => Gitlab::VisibilityLevel::INTERNAL,
      'project_id' => merge_request.target_project.id
    })

    expect(merge_request.__elasticsearch__.as_indexed_json).to eq(expected_hash)
  end

  it 'handles when a project is missing project_feature' do
    merge_request = create :merge_request
    allow(merge_request.project).to receive(:project_feature).and_return(nil)

    expect { merge_request.__elasticsearch__.as_indexed_json }.not_to raise_error
    expect(merge_request.__elasticsearch__.as_indexed_json['merge_requests_access_level']).to eq(ProjectFeature::PRIVATE)
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:record1) { create(:merge_request, source_project: project, title: 'test-mr') }
    let(:record2) { create(:merge_request, source_project: project2, title: 'test-mr') }
  end
end
