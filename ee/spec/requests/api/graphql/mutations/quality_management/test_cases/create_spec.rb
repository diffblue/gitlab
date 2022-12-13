# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create test case', feature_category: :quality_management do
  include GraphqlHelpers

  let_it_be_with_refind(:project) { create(:project, :private) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:label) { create(:label, project: project) }

  let(:variables) { { project_path: project.full_path, title: 'foo', description: 'bar', label_ids: [label.id] } }

  let(:mutation) do
    graphql_mutation(:create_test_case, variables) do
      <<~QL
         clientMutationId
         errors
         testCase {
           title
           description
           labels {
             edges {
               node {
                 id
               }
             }
           }
         }
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:create_test_case)
  end

  describe '#resolve' do
    context 'when quality management feature is not available' do
      before do
        stub_licensed_features(quality_management: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: [
                        'The resource that you are attempting to access does not exist '\
                        'or you don\'t have permission to perform this action'
                      ]
    end

    context 'when quality management feature is available' do
      before do
        stub_licensed_features(quality_management: true)
      end

      context 'when user can create test cases' do
        before_all do
          project.add_reporter(current_user)
        end

        it 'creates new test case', :aggregate_failures do
          expect { post_graphql_mutation(mutation, current_user: current_user) }.to change { Issue.count }.by(1)
          test_case = mutation_response['testCase']
          expect(test_case).not_to be_nil
          expect(test_case['title']).to eq('foo')
          expect(test_case['description']).to eq('bar')
          expect(test_case['labels']['edges'][0]["node"]["id"]).to eq(label.to_global_id.to_s)
          expect(mutation_response['errors']).to eq([])
        end

        context 'with invalid arguments' do
          let(:variables) { { not_valid: true } }

          it_behaves_like 'an invalid argument to the mutation', argument_name: :not_valid
        end
      end

      context 'when user cannot create test cases' do
        before_all do
          project.add_guest(current_user)
        end

        it_behaves_like 'a mutation that returns top-level errors',
                        errors: [
                          'The resource that you are attempting to access does not exist '\
                          'or you don\'t have permission to perform this action'
                        ]
      end
    end
  end
end
