# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a Requirement', feature_category: :requirements_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:requirement) { create(:work_item, :requirement, project: project).requirement }
  let_it_be(:iid) { requirement.iid.to_s }
  let_it_be(:work_item_iid) { requirement.requirement_issue.iid.to_s }

  let(:base_params) { { project_path: project.full_path, iid: iid } }
  let(:attributes) { { title: 'title', state: 'ARCHIVED' } }
  let(:mutation_params) { base_params.merge(attributes) }
  let(:mutation) do
    graphql_mutation(:update_requirement, mutation_params)
  end

  shared_examples 'requirement update fails' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update requirement' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { requirement.reload }
    end
  end

  def mutation_response
    graphql_mutation_response(:update_requirement)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(requirements: true)
    end

    it_behaves_like 'requirement update fails'
  end

  context 'when the user has permission' do
    before do
      project.add_reporter(current_user)
    end

    context 'when requirements are disabled' do
      before do
        stub_licensed_features(requirements: false)
      end

      it_behaves_like 'requirement update fails'
    end

    context 'when requirements are enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when identifying requirement by legacy iid' do
        it 'updates the requirement', :aggregate_failures do
          post_graphql_mutation(mutation, current_user: current_user)

          requirement_hash = mutation_response['requirement']
          expect(requirement_hash['title']).to eq('title')
          expect(requirement_hash['state']).to eq('ARCHIVED')
        end
      end

      context 'when identifying requirement by work item iid' do
        let(:base_params) { { project_path: project.full_path, work_item_iid: work_item_iid } }

        it 'updates the requirement', :aggregate_failures do
          post_graphql_mutation(mutation, current_user: current_user)

          requirement_hash = mutation_response['requirement']
          expect(requirement_hash['title']).to eq('title')
          expect(requirement_hash['state']).to eq('ARCHIVED')
        end
      end

      context 'when there are ActiveRecord validation errors' do
        let(:attributes) { { title: '' } }

        it_behaves_like 'a mutation that returns errors in the response',
          errors: ['Title can\'t be blank']

        it 'does not update the requirement' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.not_to change { requirement.reload }
        end
      end

      context 'when there are no update params' do
        let(:attributes) { {} }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ['At least one of title, state, last_test_report_state, description is required']
      end

      context 'when neither iid nor work_item_iid are given' do
        let(:base_params) { { project_path: project.full_path } }
        let(:attributes) { { title: 'new title' } }

        it_behaves_like 'a mutation that returns top-level errors',
                        errors: ['One and only one of iid or workItemIid is required']
      end

      context 'when there are no update params nor iid params' do
        let(:base_params) { { project_path: project.full_path } }
        let(:attributes) { {} }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: /one of iid or workItemIid is required; At least one of title/
      end

      context 'when both iid and work_item_iid are given' do
        let(:base_params) { { project_path: project.full_path, iid: iid, work_item_iid: work_item_iid } }
        let(:attributes) { { title: 'new title' } }

        it_behaves_like 'a mutation that returns top-level errors',
                        errors: ['One and only one of iid or workItemIid is required']
      end
    end
  end
end
