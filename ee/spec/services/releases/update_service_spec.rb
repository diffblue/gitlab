# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::UpdateService do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:user) { create(:user) }
  let(:params) { { tag: tag_name } }
  let!(:release) { create(:release, project: project, tag: tag_name) }
  let(:tag_name) { 'v1.1.0' }
  let(:service) { described_class.new(project, user, params_with_milestones) }

  before do
    project.add_developer(user)
  end

  describe 'group milestones' do
    context 'when a group milestone is passed' do
      let(:group_milestone) { create(:milestone, group: group, title: 'g1') }
      let(:params_with_milestones) { params.merge({ milestones: [group_milestone.title] }) }

      context 'when there is no project milestone' do
        context 'when licenced' do
          before do
            stub_licensed_features(group_milestone_project_releases: true)
          end

          it 'adds the group milestone', :aggregate_failures do
            result = service.execute
            release.reload

            expect(release.milestones).to match_array([group_milestone])
            expect(result[:milestones_updated]).to be_truthy
          end
        end

        context 'when unlicensed' do
          it 'returns an error', :aggregate_failures do
            result = service.execute

            expect(result[:status]).to eq(:error)
            expect(result[:milestones_updated]).to be_falsy
            expect(result[:message]).to match(/None of the group milestones have the same project as the release/)
          end
        end
      end

      context 'when there is an existing project milestone' do
        let(:project_milestone) { create(:milestone, project: project, title: 'p1') }

        before do
          release.milestones << project_milestone
        end

        context 'when licenced' do
          before do
            stub_licensed_features(group_milestone_project_releases: true)
          end

          it 'replaces the project milestone with the group milestone', :aggregate_failures do
            result = service.execute
            release.reload

            expect(release.milestones).to match_array([group_milestone])
            expect(result[:milestones_updated]).to be_truthy
          end
        end

        context 'when unlicensed' do
          it 'returns an error', :aggregate_failures do
            result = service.execute

            expect(result[:status]).to eq(:error)
            expect(result[:message]).to match(/None of the group milestones have the same project as the release/)
          end
        end
      end

      context 'when an empty milestone array is passed' do
        let(:project_milestone) { create(:milestone, project: project, title: 'p1') }
        let(:params_with_milestones) { params.merge({ milestones: [] }) }

        before do
          release.milestones << project_milestone
        end

        it 'clears the milestone array', :aggregate_failures do
          result = service.execute
          release.reload

          expect(release.milestones).to match_array([])
          expect(result[:milestones_updated]).to be_truthy
        end
      end

      context 'when a supergroup milestone is passed' do
        let(:group) { create(:group, parent: supergroup) }
        let(:supergroup) { create(:group) }
        let(:supergroup_milestone) { create(:milestone, group: supergroup, title: 'sg1') }
        let(:params_with_milestones) { params.merge({ milestones: [supergroup_milestone.title] }) }

        it 'ignores the milestone' do
          service.execute
          release.reload

          expect(release.milestones).to match_array([])
        end
      end
    end
  end
end
