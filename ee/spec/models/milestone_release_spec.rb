# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MilestoneRelease do
  let(:project) { create(:project) }
  let(:release) { create(:release, project: project) }

  describe 'validations' do
    let(:milestone_release) { build(:milestone_release, release: release, milestone: milestone) }

    subject { milestone_release }

    context 'when it is a project milestone' do
      context 'when milestone and release have the same project' do
        let(:milestone) { create(:milestone, project: project, group: nil) }

        it { is_expected.to be_valid }
      end

      context 'when milestone and release do not have the same project' do
        let(:milestone) { create(:milestone, project: create(:project), group: nil) }

        it { is_expected.not_to be_valid }
      end
    end

    context 'when it is a group milestone' do
      let(:milestone) { create(:milestone, project: nil, group: group) }

      context 'when group and release have the same project' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }

        context 'when it is licenced' do
          before do
            stub_licensed_features(group_milestone_project_releases: true)
          end

          it { is_expected.to be_valid }
        end

        context 'when it is not licensed' do
          it { is_expected.not_to be_valid }
        end
      end

      context 'when milestone and group do not have the same project' do
        let(:group) { create(:group) }
        let(:project2) { create(:project, group: group) }

        context 'when it is licenced' do
          before do
            stub_licensed_features(group_milestone_project_releases: true)
          end

          it { is_expected.not_to be_valid }
        end

        it { is_expected.not_to be_valid }
      end

      context 'when it is a supergroup milestone' do
        let(:supergroup) { create(:group) }
        let(:group) { create(:group, parent: supergroup) }
        let(:project) { create(:project, group: group) }
        let(:milestone) { create(:milestone, project: nil, group: supergroup) }

        context 'when it is licenced' do
          before do
            stub_licensed_features(group_milestone_project_releases: true)
          end

          it { is_expected.not_to be_valid }
        end

        it { is_expected.not_to be_valid }
      end
    end
  end
end
