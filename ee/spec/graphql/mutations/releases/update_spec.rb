# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Releases::Update do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }
  let_it_be(:group_milestone) { create(:milestone, group: group, title: '13.1') }
  let_it_be(:developer) { create(:user) }

  let_it_be(:tag) { 'v1.1.0' }

  let_it_be(:release) do
    create(:release, project: project, tag: tag)
  end

  let(:milestones) { [milestone_12_3.title, milestone_12_4.title] }

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  let(:mutation_arguments) do
    {
      project_path: project.full_path,
      tag: tag,
      milestones: milestones
    }
  end

  around do |example|
    freeze_time { example.run }
  end

  before do
    project.add_developer(developer)
  end

  describe '#resolve' do
    let(:current_user) { developer }
    let(:updated_release) { subject[:release] }

    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    context 'milestones' do
      context 'when the provided milestones include a group milestone' do
        let(:milestones) { [group_milestone.title] }

        context 'when the group milestone association feature is licensed' do
          before do
            stub_licensed_features(group_milestone_project_releases: true)
          end

          it 'updates the milestone associations' do
            expect(updated_release.milestones).to eq([group_milestone])
          end
        end

        context 'when the group milestone association feature is not licensed' do
          before do
            stub_licensed_features(group_milestone_project_releases: false)
          end

          it 'returns the updated release as nil' do
            expect(updated_release).to be_nil
          end

          it 'returns a validation error' do
            expect(subject[:errors]).to eq(['Validation failed: None of the group milestones have the same project as the release'])
          end
        end
      end
    end
  end
end
