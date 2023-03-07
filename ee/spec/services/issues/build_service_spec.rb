# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::BuildService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }

  let(:user) { developer }

  before do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  def build_issue(issue_params = {})
    described_class.new(container: project, current_user: user, params: issue_params).execute
  end

  context 'with an issue template' do
    describe '#execute' do
      let(:project) { build(:project, issues_template: 'Work hard, play hard!') }

      it 'fills in the template in the description' do
        issue = build_issue

        expect(issue.description).to eq('Work hard, play hard!')
      end

      it 'fills in the template, followed by the query parameter, in the description' do
        issue = build_issue(description: 'Travailler dur, jouer dur!')

        expect(issue.description).to eq("Work hard, play hard!\nTravailler dur, jouer dur!")
      end
    end
  end

  context 'for a single thread' do
    describe '#execute' do
      let(:merge_request) { create(:merge_request, title: "Hello world", source_project: project) }
      let(:discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, note: "Almost done").to_discussion }

      context 'with an issue template' do
        let(:project) { create(:project, :repository, issues_template: 'Work hard, play hard!') }

        it 'picks the thread description over the issue template' do
          issue = build_issue(
            merge_request_to_resolve_discussions_of: merge_request.iid,
            discussion_to_resolve: discussion.id
          )

          expect(issue.description).to include('Almost done')
        end
      end
    end
  end

  describe '#execute' do
    before do
      stub_licensed_features(quality_management: true, requirements: true)
    end

    context 'as developer' do
      WorkItems::Type.allowed_types_for_issues do |issue_type|
        it "sets the issue type to #{issue_type}" do
          issue = build_issue(issue_type: issue_type)

          expect(issue.issue_type).to eq(issue_type)
        end
      end
    end

    context 'as guest' do
      let(:user) { guest }

      context 'setting issue type' do
        [:test_case, :requirement].each do |issue_type|
          it "cannot set the issue type to #{issue_type}" do
            issue = build_issue(issue_type: issue_type)

            expect(issue.issue_type).to eq('issue')
          end
        end
      end
    end
  end
end
