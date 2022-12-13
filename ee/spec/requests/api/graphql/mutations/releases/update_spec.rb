# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing release', feature_category: :release_orchestration do
  include GraphqlHelpers
  include Presentable

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }
  let_it_be(:group_milestone) { create(:milestone, group: group, title: '13.1') }
  let_it_be(:developer) { create(:user) }
  let_it_be(:tag_name) { 'v1.1.0' }
  let_it_be(:release) do
    create(:release, project: project, tag: tag_name)
  end

  let(:mutation_name) { :release_update }

  let(:milestones) { [milestone_12_3.title, milestone_12_4.title, group_milestone.title] }

  let(:mutation_arguments) do
    {
      projectPath: project.full_path,
      tagName: tag_name,
      milestones: milestones
    }
  end

  let(:mutation) do
    graphql_mutation(mutation_name, mutation_arguments, <<~FIELDS)
      release {
        milestones {
          nodes {
            title
          }
        }
      }
      errors
    FIELDS
  end

  let(:update_release) { post_graphql_mutation(mutation, current_user: developer) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  before do
    project.add_developer(developer)
  end

  context 'when the provided milestones include a group milestone' do
    context 'when the group milestone association feature is licensed' do
      before do
        stub_licensed_features(group_milestone_project_releases: true)

        update_release
      end

      it 'returns no errors' do
        expect(graphql_errors).not_to be_present
      end

      it 'updates a release with both project and group milestone associations' do
        returned_milestone_titles = mutation_response.dig(:release, :milestones, :nodes)
                                                     .map { |m| m[:title] }

        expect(returned_milestone_titles).to eq([
                                                  milestone_12_3.title,
                                                  milestone_12_4.title,
                                                  group_milestone.title
                                                ])
      end
    end

    context 'when the group milestone association feature is not licensed' do
      before do
        stub_licensed_features(group_milestone_project_releases: false)

        update_release
      end

      it 'returns an error-as-data field with a message about an invalid license' do
        expect(mutation_response[:release]).to be_nil
        expect(mutation_response[:errors].count).to eq(1)
        expect(mutation_response[:errors].first).to match('Validation failed: None of the group milestones have the same project as the release')
      end
    end
  end
end
