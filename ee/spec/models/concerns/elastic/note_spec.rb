# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Note, :elastic, :clean_gitlab_redis_shared_state, feature_category: :global_search do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it_behaves_like 'limited indexing is enabled' do
    let_it_be(:object) { create :note, project: project }
    let_it_be(:group) { create(:group) }
    let(:group_object) do
      project = create :project, name: 'test1', group: group
      create :note, project: project
    end

    describe '#searchable?' do
      before do
        create :elasticsearch_indexed_project, project: project
      end

      it 'also works on diff notes' do
        notes = []
        notes << create(:diff_note_on_merge_request, note: "term")
        notes << create(:diff_note_on_commit, note: "term")
        notes << create(:legacy_diff_note_on_merge_request, note: "term")
        notes << create(:legacy_diff_note_on_commit, note: "term")

        notes.each do |note|
          create :elasticsearch_indexed_project, project: note.noteable.project

          expect(note.searchable?).to be_truthy
        end
      end
    end
  end

  it "searches notes", :sidekiq_inline do
    project = create :project, :public
    issue = create :issue, project: project

    note = create :note, note: 'bla-bla term1', project: issue.project
    create :note, project: issue.project

    # The note in the project you have no access to except as an administrator
    outside_note = create :note, note: 'bla-bla term2'

    ensure_elasticsearch_index!

    options = { project_ids: [issue.project.id] }

    expect(described_class.elastic_search('term1 | term2', options: options).records).to contain_exactly(note)
    expect(described_class.elastic_search('bla-bla', options: options).records).to contain_exactly(note)
    expect(described_class.elastic_search('bla-bla', options: { project_ids: :any }).records).to contain_exactly(outside_note)
  end

  it "names elasticsearch queries" do
    described_class.elastic_search('*').total_count

    assert_named_queries("note:match:search_terms", "note:authorized")
  end

  it "indexes && searches diff notes" do
    notes = []

    Sidekiq::Testing.inline! do
      notes << create(:diff_note_on_merge_request, note: "term")
      notes << create(:diff_note_on_commit, note: "term")
      notes << create(:legacy_diff_note_on_merge_request, note: "term")
      notes << create(:legacy_diff_note_on_commit, note: "term")

      notes.each do |note|
        note.project.update!(visibility: Gitlab::VisibilityLevel::PUBLIC)
      end

      ensure_elasticsearch_index!
    end

    project_ids = notes.map { |note| note.noteable.project.id }
    options = { project_ids: project_ids }

    expect(described_class.elastic_search('term', options: options).total_count).to eq(4)
  end

  describe 'json serialization' do
    using RSpec::Parameterized::TableSyntax

    it "returns json with all needed elements" do
      assignee = create(:user)
      project = create(:project)
      issue = create(:issue, project: project, assignees: [assignee])
      note = create(:note, noteable: issue, project: project)

      expected_hash = note.attributes.extract!(
        'id',
        'note',
        'project_id',
        'noteable_type',
        'noteable_id',
        'created_at',
        'updated_at',
        'confidential',
        'internal'
      ).merge({
                'issue' => {
                  'assignee_id' => issue.assignee_ids,
                  'author_id' => issue.author_id,
                  'confidential' => issue.confidential
                },
                'hashed_root_namespace_id' => project.namespace.hashed_root_namespace_id,
                'type' => note.es_type,
                'visibility_level' => project.visibility_level,
                'issues_access_level' => project.issues_access_level
              })

      expect(note.__elasticsearch__.as_indexed_json).to eq(expected_hash)
    end

    context 'when internal note migration has not been finished' do
      before do
        set_elasticsearch_migration_to(:add_internal_to_notes, including: false)
      end

      it 'does not include the internal' do
        note = create(:note_on_issue)

        expect(note.__elasticsearch__.as_indexed_json.keys).not_to include('internal')
      end
    end

    it 'raises Elastic::Latest::DocumentShouldBeDeletedFromIndexError when noteable is nil' do
      note = create(:note_on_issue)
      allow(note).to receive(:noteable).and_return(nil)

      expect { note.__elasticsearch__.as_indexed_json }.to raise_error(::Elastic::Latest::DocumentShouldBeDeletedFromIndexError)
    end

    where(:note_type, :project_feature_permission, :access_level) do
      :note_on_issue                              | ProjectFeature::ENABLED      | 'issues_access_level'
      :note_on_project_snippet                    | ProjectFeature::DISABLED     | 'snippets_access_level'
      :note_on_personal_snippet                   | nil                          | nil
      :note_on_merge_request                      | ProjectFeature::PUBLIC       | 'merge_requests_access_level'
      :note_on_commit                             | ProjectFeature::PRIVATE      | 'repository_access_level'
      :diff_note_on_merge_request                 | ProjectFeature::PUBLIC       | 'merge_requests_access_level'
      :diff_note_on_commit                        | ProjectFeature::PRIVATE      | 'repository_access_level'
      :diff_note_on_design                        | ProjectFeature::ENABLED      | nil
      :legacy_diff_note_on_merge_request          | ProjectFeature::PUBLIC       | 'merge_requests_access_level'
      :legacy_diff_note_on_commit                 | ProjectFeature::PRIVATE      | 'repository_access_level'
      :note_on_alert                              | ProjectFeature::PRIVATE      | nil
      :note_on_design                             | ProjectFeature::ENABLED      | nil
      :note_on_epic                               | nil                          | nil
      :note_on_vulnerability                      | ProjectFeature::PRIVATE      | nil
      :discussion_note_on_vulnerability           | ProjectFeature::PRIVATE      | nil
      :discussion_note_on_merge_request           | ProjectFeature::PUBLIC       | 'merge_requests_access_level'
      :discussion_note_on_issue                   | ProjectFeature::ENABLED      | 'issues_access_level'
      :discussion_note_on_project_snippet         | ProjectFeature::DISABLED     | 'snippets_access_level'
      :discussion_note_on_personal_snippet        | nil                          | nil
      :discussion_note_on_commit                  | ProjectFeature::PRIVATE      | 'repository_access_level'
      :track_mr_picking_note                      | nil                          | nil
    end

    with_them do
      let!(:note) { create(note_type) } # rubocop:disable Rails/SaveBang
      let(:project) { note.project }

      let(:note_json) { note.__elasticsearch__.as_indexed_json }

      before do
        project.project_feature.update_attribute(access_level.to_sym, project_feature_permission) if access_level.present?
      end

      it 'contains the correct permissions', :aggregate_failures do
        if access_level
          expect(note_json).to have_key(access_level)
          expect(note_json[access_level]).to eq(project_feature_permission)
        end

        expected_visibility_level = project&.visibility_level || Gitlab::VisibilityLevel::PRIVATE
        expect(note_json).to have_key('visibility_level')
        expect(note_json['visibility_level']).to eq(expected_visibility_level)
      end

      context 'when the project does not exist' do
        before do
          note.project = nil
        end

        it 'has DISABLED access_level' do
          if access_level
            expect(note_json).to have_key(access_level)
            expect(note_json[access_level]).to eq(ProjectFeature::DISABLED)
          end
        end
      end
    end
  end

  it 'does not track system note updates' do
    note = create(:note, :system)

    expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)

    note.update!(note: 'some other text here')
  end

  it 'uses same index for Note subclasses', :eager_load do
    Note.subclasses.each do |note_class|
      expect(note_class.index_name).to eq(Note.index_name)
      expect(note_class.document_type).to eq(Note.document_type)
      expect(note_class.__elasticsearch__.mappings.to_hash).to eq(Note.__elasticsearch__.mappings.to_hash)
    end
  end

  context 'notes to confidential issues' do
    it "does not find note" do
      issue = create :issue, :confidential

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        ensure_elasticsearch_index!
      end

      options = { project_ids: [issue.project.id] }

      expect(Note.elastic_search('term', options: options).total_count).to eq(0)
    end

    it "finds note when user is authorized to see it", :sidekiq_might_not_need_inline do
      user = create :user
      issue = create :issue, :confidential, author: user
      issue.project.add_guest user

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        ensure_elasticsearch_index!
      end

      options = { project_ids: [issue.project.id], current_user: user }

      expect(Note.elastic_search('term', options: options).total_count).to eq(1)
    end

    shared_examples 'notes finder' do |user_type, no_of_notes|
      it "finds #{no_of_notes} notes for #{user_type}", :sidekiq_might_not_need_inline do
        superuser = create(user_type) # rubocop:disable Rails/SaveBang
        issue = create(:issue, :confidential, author: create(:user))

        Sidekiq::Testing.inline! do
          create_notes_for(issue, 'bla-bla term')
          ensure_elasticsearch_index!
        end

        options = { project_ids: [issue.project.id], current_user: superuser }

        expect(Note.elastic_search('term', options: options).total_count).to eq(no_of_notes)
      end
    end

    context 'when admin mode is enabled', :enable_admin_mode do
      it_behaves_like 'notes finder', :admin, 1
    end

    it_behaves_like 'notes finder', :admin, 0

    it_behaves_like 'notes finder', :auditor, 1

    it "return notes with matching content for project members", :sidekiq_might_not_need_inline do
      user = create :user
      issue = create :issue, :confidential, author: user

      member = create(:user)
      issue.project.add_developer(member)

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        ensure_elasticsearch_index!
      end

      options = { project_ids: [issue.project.id], current_user: member }

      expect(Note.elastic_search('term', options: options).total_count).to eq(1)
    end

    it "does not return notes with matching content for project members with guest role" do
      user = create :user
      issue = create :issue, :confidential, author: user

      member = create(:user)
      issue.project.add_guest(member)

      Sidekiq::Testing.inline! do
        create_notes_for(issue, 'bla-bla term')
        ensure_elasticsearch_index!
      end

      options = { project_ids: [issue.project.id], current_user: member }

      expect(Note.elastic_search('term', options: options).total_count).to eq(0)
    end
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:issue1) { create(:issue, project: project) }
    let(:issue2) { create(:issue, project: project2) }
    let(:record1) { create :note, note: 'test-note', project: issue1.project, noteable: issue1 }
    let(:record2) { create :note, note: 'test-note', project: issue2.project, noteable: issue2 }
  end

  def create_notes_for(issue, note)
    create :note, note: note, project: issue.project, noteable: issue
    create :note, project: issue.project, noteable: issue
  end
end
