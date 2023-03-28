# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::VariablesController, feature_category: :secrets_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:variable) { create(:ci_group_variable, group: group, environment_scope: '*') }

  before do
    sign_in(user)
    group.add_member(user, :owner)
  end

  describe 'PATCH #update' do
    let(:params) do
      {
        group_id: group,
        variables_attributes: [{
          id: variable.id,
          environment_scope: 'production'
        }]
      }
    end

    before do
      stub_licensed_features(group_scoped_ci_variables: scoped_variables_available)
    end

    subject { patch :update, params: params, format: :json }

    context 'scoped variables are available' do
      let(:scoped_variables_available) { true }

      it 'updates the environment scope' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(variable.reload.environment_scope).to eq('production')
      end
    end

    context 'scoped variables are not available' do
      let(:scoped_variables_available) { false }

      it 'does not update the environment scope' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(variable.reload.environment_scope).to eq('*')
      end
    end
  end
end
