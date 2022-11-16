# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::TodosController, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }

  describe 'POST create' do
    def post_create
      post :create,
        params: {
          group_id: group,
          issuable_id: epic.id,
          issuable_type: 'epic'
        },
        format: :json
    end

    shared_examples_for 'todo for inaccessible resource' do
      it 'does not create todo because resource can not be found' do
        sign_in(user)

        expect do
          post_create
        end.to change { user.todos.count }.by(0)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when epic is not confidential' do
      let_it_be(:group) { create(:group, :private) }
      let_it_be(:epic) { create(:epic, group: group) }

      let(:parent) { group }

      context 'when epics are available' do
        before do
          stub_licensed_features(epics: true)
        end

        it_behaves_like 'todos actions'
      end

      context 'when epics are not available' do
        before do
          stub_licensed_features(epics: false)
          group.add_developer(user)
        end

        it_behaves_like 'todo for inaccessible resource'
      end
    end

    context 'when the user can not access confidential epic in public group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:epic) { create(:epic, :confidential, group: group) }

      before do
        stub_licensed_features(epics: true)
      end

      it_behaves_like 'todo for inaccessible resource'
    end
  end
end
