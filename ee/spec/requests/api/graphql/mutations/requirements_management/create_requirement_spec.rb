# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a Requirement', feature_category: :requirements_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:attributes) { { title: 'title' } }
  let(:mutation) do
    params = { project_path: project.full_path }.merge(attributes)

    graphql_mutation(:create_requirement, params)
  end

  def mutation_response
    graphql_mutation_response(:create_requirement)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(requirements: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create requirement' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(RequirementsManagement::Requirement, :count)
    end
  end

  context 'when the user has permission' do
    before do
      project.add_reporter(current_user)
    end

    context 'when requirements are disabled' do
      before do
        stub_licensed_features(requirements: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
    end

    context 'when requirements are enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      it 'creates the requirement' do
        post_graphql_mutation(mutation, current_user: current_user)

        requirement_hash = mutation_response['requirement']
        expect(requirement_hash['title']).to eq('title')
        expect(requirement_hash['state']).to eq('OPENED')
        expect(requirement_hash['author']['username']).to eq(current_user.username)
      end

      context 'when there are ActiveRecord validation errors' do
        let(:attributes) { { title: '' } }

        it_behaves_like 'a mutation that returns errors in the response',
          errors: ["Title can't be blank"]

        it 'does not create the requirement' do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(RequirementsManagement::Requirement, :count)
        end
      end

      it_behaves_like 'has spam protection' do
        let(:mutation_class) { Mutations::RequirementsManagement::CreateRequirement }
      end
    end
  end
end
