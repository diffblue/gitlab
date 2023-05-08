# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Converts a work item to a new type", feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }
  let_it_be(:new_type) { create(:work_item_type, :objective, :default) }
  let_it_be(:work_item, refind: true) do
    create(:work_item, :key_result, project: project, start_date: Time.current, due_date: Time.current + 1.day)
  end

  let(:mutation) { graphql_mutation(:workItemConvert, input) }
  let(:mutation_response) { graphql_mutation_response(:work_item_convert) }
  let(:input) do
    {
      'id' => work_item.to_global_id.to_s,
      'work_item_type_id' => new_type.to_global_id.to_s
    }
  end

  context 'when the work item type is not part of the license' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(okrs: false)
    end

    it 'does not convert the work item', :aggregate_failures do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { work_item.reload.work_item_type }

      expect(response).to have_gitlab_http_status(:success)
      expect(work_item.reload.work_item_type.base_type).to eq('key_result')
      expect(work_item.start_date).to be_present
      expect(work_item.due_date).to be_present
      expect(graphql_errors).to include(
        a_hash_including('message' => "You are not allowed to change the Work Item type to Objective.")
      )
    end
  end

  context 'when user has permissions to convert the work item type' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(okrs: true)
    end

    it 'converts the work item', :aggregate_failures do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { work_item.reload.work_item_type }.to(new_type)

      expect(response).to have_gitlab_http_status(:success)
      expect(work_item.reload.work_item_type.base_type).to eq('objective')
      expect(work_item.start_date).to be_nil
      expect(work_item.due_date).to be_nil
      expect(mutation_response['workItem']).to include('id' => work_item.to_global_id.to_s)
    end
  end
end
