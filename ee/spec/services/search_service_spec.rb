# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchService do
  describe '#search_objects' do
    context 'redacting search results (repository)', :elastic, :sidekiq_inline do
      let(:project) { create(:project, :repository) }
      let(:user) { project.creator }

      subject(:search_service) { described_class.new(user, search: '*', scope: scope, page: 1) }

      shared_examples 'it redacts incorrect results' do
        before do
          stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
          Gitlab::Elastic::Indexer.new(project).run
          ensure_elasticsearch_index!

          # disable permission to test redaction
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(user, ability, a_kind_of(model_class)).and_return(allowed)
        end

        context 'when allowed' do
          let(:allowed) { true }

          it 'does nothing' do
            results = subject.search_objects

            expect(results).not_to be_empty
            expect(results).to all(be_an(model_class))
          end
        end

        context 'when disallowed' do
          let(:allowed) { false }

          it 'redacts results' do
            results = subject.search_objects

            expect(results).to be_empty
          end
        end
      end

      context 'commits' do
        let(:scope) { 'commits' }
        let(:model_class) { Commit }
        let(:ability) { :read_commit }

        it_behaves_like 'it redacts incorrect results'
      end

      context 'blobs' do
        let(:scope) { 'blobs' }
        let(:model_class) { Gitlab::Search::FoundBlob }
        let(:ability) { :read_blob }

        it_behaves_like 'it redacts incorrect results'
      end

      context 'wiki blobs' do
        let(:project) { create(:project, :wiki_repo) }
        let(:scope) { 'wiki_blobs' }
        let(:model_class) { Gitlab::Search::FoundWikiPage }
        let(:ability) { :read_wiki_page }

        it_behaves_like 'it redacts incorrect results' do
          before do
            create(:wiki_page, wiki: project.wiki)
            Gitlab::Elastic::Indexer.new(project, wiki: true).run
            ensure_elasticsearch_index!
          end
        end
      end
    end

    context 'redacting search results' do
      let_it_be(:user) { create(:user) }

      # Resources the user has access to
      let(:project) { create(:project) }
      let(:issue_in_project) { create(:issue, project: project) }
      let(:note_on_issue_in_project) { create(:note, project: project, noteable: issue_in_project) }
      let(:merge_request_in_project) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
      let(:milestone_in_project) { create(:milestone, project: project) }

      # Resources the user does not have access to
      let(:unauthorized_project) { create(:project, :repository, :wiki_repo) }
      let(:issue1_in_unauthorized_project) { create(:issue, project: unauthorized_project) }
      let(:issue2_in_unauthorized_project) { create(:issue, project: unauthorized_project) }
      let(:note_on_unauthorized_issue) { create(:note, project: unauthorized_project, noteable: issue1_in_unauthorized_project) }
      let(:merge_request_in_unauthorized_project) { create(:merge_request_with_diffs, target_project: unauthorized_project, source_project: unauthorized_project) }
      let(:milestone_in_unauthorized_project) { create(:milestone, project: unauthorized_project) }

      let(:search_service) { described_class.new(user, search: 'some-search-string', page: 1) }
      let(:mock_global_service) { instance_double(Search::GlobalService, scope: 'some-scope') }
      let(:mock_results) { instance_double(Gitlab::Elastic::SearchResults) }

      subject { search_service.search_objects }

      before do
        project.add_maintainer(user)
        allow(Search::GlobalService).to receive(:new).with(user, anything).and_return(mock_global_service)
        allow(mock_global_service).to receive(:execute).and_return(mock_results)
      end

      it 'redacts projects the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                project,
                unauthorized_project
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(search_service.send(:logger))
          .to receive(:error)
          .with(hash_including(
                  message: "redacted_search_results",
                  current_user_id: user.id,
                  query: 'some-search-string',
                  filtered: array_including(
                    [
                      { class_name: "Project", id: unauthorized_project.id, ability: :read_project }
                    ])))

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(project)
      end

      it 'redacts issues the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                issue_in_project,
                issue1_in_unauthorized_project,
                issue2_in_unauthorized_project
              ],
              total_count: 3,
              limit: 3,
              offset: 0
            )
          )

        expect(search_service.send(:logger))
          .to receive(:error)
          .with(hash_including(
                  message: "redacted_search_results",
                  current_user_id: user.id,
                  query: 'some-search-string',
                  filtered: array_including(
                    [
                      { class_name: "Issue", id: issue1_in_unauthorized_project.id, ability: :read_issue },
                      { class_name: "Issue", id: issue2_in_unauthorized_project.id, ability: :read_issue }
                    ])))

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(issue_in_project)
      end

      it 'redacts merge requests the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                merge_request_in_project,
                merge_request_in_unauthorized_project
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(merge_request_in_project)
      end

      it 'redacts milestones the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                milestone_in_project,
                milestone_in_unauthorized_project
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(milestone_in_project)
      end

      it 'redacts notes the user does not have access to' do
        allow(mock_results).to receive(:objects)
          .and_return(
            Kaminari.paginate_array(
              [
                note_on_issue_in_project,
                note_on_unauthorized_issue
              ],
              total_count: 2,
              limit: 2,
              offset: 0
            )
          )

        expect(subject).to be_kind_of(Kaminari::PaginatableArray)
        expect(subject).to contain_exactly(note_on_issue_in_project)
      end
    end
  end

  describe '#projects' do
    let_it_be(:user) { create(:user) }
    let_it_be(:accessible_project) { create(:project, :public) }
    let_it_be(:inaccessible_project) { create(:project, :private) }

    context 'when all projects are accessible' do
      let_it_be(:accessible_project_2) { create(:project, :public) }

      it 'returns the project' do
        project_ids = [accessible_project.id, accessible_project_2.id].join(',')
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to match_array [accessible_project, accessible_project_2]
      end

      it 'returns the projects for guests' do
        search_project = create :project
        search_project.add_guest(user)
        project_ids = [accessible_project.id, accessible_project_2.id, search_project.id].join(',')
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to match_array [accessible_project, accessible_project_2, search_project]
      end

      it 'handles spaces in the param' do
        project_ids = [accessible_project.id, accessible_project_2.id].join(',    ')
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to match_array [accessible_project, accessible_project_2]
      end

      it 'returns nil if projects param is not a String' do
        project_ids = accessible_project.id
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to be_nil
      end
    end

    context 'when some projects are accessible' do
      it 'returns only accessible projects' do
        project_ids = [accessible_project.id, inaccessible_project.id].join(',')
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to match_array [accessible_project]
      end
    end

    context 'when no projects are accessible' do
      it 'returns nil' do
        project_ids = "#{inaccessible_project.id}"
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to be_nil
      end
    end

    context 'when no project_ids are provided' do
      it 'returns nil' do
        projects = described_class.new(user).projects

        expect(projects).to be_nil
      end
    end

    context 'when the advanced_search_multi_project_select feature is not enabled' do
      before do
        stub_feature_flags(advanced_search_multi_project_select: false)
      end

      it 'returns nil' do
        project_ids = "#{accessible_project.id}"
        projects = described_class.new(user, project_ids: project_ids).projects

        expect(projects).to be_nil
      end
    end
  end
end
