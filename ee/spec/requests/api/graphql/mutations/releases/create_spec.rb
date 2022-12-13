# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new release', feature_category: :release_orchestration do
  include GraphqlHelpers
  include Presentable

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }
  let_it_be(:group_milestone) { create(:milestone, group: group, title: '13.1') }
  let_it_be(:developer) { create(:user) }

  let(:mutation_name) { :release_create }

  let(:tag_name) { 'v7.12.5' }
  let(:ref) { 'master' }
  let(:milestones) { [milestone_12_3.title, milestone_12_4.title, group_milestone.title] }

  let(:mutation_arguments) do
    {
      projectPath: project.full_path,
      tagName: tag_name,
      ref: ref,
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

  let(:create_release) { post_graphql_mutation(mutation, current_user: developer) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  before do
    project.add_developer(developer)
  end

  context 'when the provided milestones include a group milestone' do
    context 'when the group milestone association feature is licensed' do
      before do
        stub_licensed_features(group_milestone_project_releases: true)
      end

      it 'returns no errors' do
        create_release

        expect(graphql_errors).not_to be_present
      end

      it 'creates a release with both project and group milestone associations' do
        create_release

        returned_milestone_titles = mutation_response.dig(:release, :milestones, :nodes)
                                                     .map { |m| m[:title] }

        expect(returned_milestone_titles).to eq(
          [
            milestone_12_3.title,
            milestone_12_4.title,
            group_milestone.title
          ])
      end
    end

    context 'when the group milestone association feature is not licensed' do
      before do
        stub_licensed_features(group_milestone_project_releases: false)
      end

      it 'returns an error-as-data field with a message about an invalid license' do
        create_release

        expect(mutation_response[:release]).to be_nil
        expect(mutation_response[:errors].count).to eq(1)

        # Weird error message will be fixed in https://gitlab.com/gitlab-org/gitlab/-/issues/277397
        expect(mutation_response[:errors].first).to match('Validation failed: Milestone releases is invalid, Milestone releases None of the group milestones have the same project as the release,,')
      end
    end
  end
end
