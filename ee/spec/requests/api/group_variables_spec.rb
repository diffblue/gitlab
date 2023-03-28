# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupVariables, feature_category: :secrets_management do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  describe 'GET /groups/:id/variables/:key' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    before do
      group.add_owner(user)
    end

    context 'when there are two variables with the same key on different environments' do
      let!(:var1) { create(:ci_group_variable, group: group, key: 'key1', environment_scope: 'staging') }
      let!(:var2) { create(:ci_group_variable, group: group, key: 'key1', environment_scope: 'production') }

      context 'when filter[environment_scope] is not passed' do
        it 'returns 409' do
          get api("/groups/#{group.id}/variables/key1", user)

          expect(response).to have_gitlab_http_status(:conflict)
        end
      end

      context 'when filter[environment_scope] is passed' do
        it 'returns the variable' do
          get api("/groups/#{group.id}/variables/key1", user), params: { 'filter[environment_scope]': 'production' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['value']).to eq(var2.value)
        end
      end

      context 'when wrong filter[environment_scope] is passed' do
        it 'returns not_found' do
          get api("/groups/#{group.id}/variables/key1", user), params: { 'filter[environment_scope]': 'invalid' }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'when there is only one variable with provided key' do
          it 'returns not_found' do
            get api("/groups/#{group.id}/variables/#{variable.key}", user), params: { 'filter[environment_scope]': 'invalid' }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'POST /groups/:id/variables' do
    context 'scoped variables' do
      let(:params) do
        {
          key: 'KEY',
          value: 'VALUE',
          environment_scope: 'production'
        }
      end

      subject { post api("/groups/#{group.id}/variables", user), params: params }

      before do
        group.add_owner(user)
        stub_licensed_features(group_scoped_ci_variables: scoped_variables_available)
      end

      context ':group_scoped_ci_variables licensed feature is available' do
        let(:scoped_variables_available) { true }

        it 'creates a variable with the provided environment scope' do
          expect { subject }.to change { group.variables.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['environment_scope']).to eq('production')
        end

        context 'a variable with the same key and scope exists already' do
          let!(:variable) { create(:ci_group_variable, group: group, key: 'KEY', environment_scope: 'production') }

          it 'does not create a variable' do
            expect { subject }.not_to change { group.variables.count }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context ':group_scoped_ci_variables licensed feature is not available' do
        let(:scoped_variables_available) { false }

        it 'creates a variable, but does not use the provided environment scope' do
          expect { subject }.to change { group.variables.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['environment_scope']).to eq('*')
        end

        context 'a variable with the same key and scope exists already' do
          let!(:variable) { create(:ci_group_variable, group: group, key: 'KEY', environment_scope: '*') }

          it 'does not create a variable' do
            expect { subject }.not_to change { group.variables.count }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end
  end

  describe 'PUT /groups/:id/variables/:key' do
    let!(:variable) { create(:ci_group_variable, group: group, environment_scope: '*') }

    subject { put api("/groups/#{group.id}/variables/#{variable.key}", user), params: { environment_scope: 'production' } }

    context 'scoped variables' do
      before do
        group.add_owner(user)
        stub_licensed_features(group_scoped_ci_variables: scoped_variables_available)
      end

      context ':group_scoped_ci_variables licensed feature is available' do
        let(:scoped_variables_available) { true }

        it 'updates the variable' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(variable.reload.environment_scope).to eq('production')
          expect(json_response['environment_scope']).to eq('production')
        end

        context 'a variable with the same key and scope exists already' do
          let!(:conflicting_variable) { create(:ci_group_variable, group: group, key: variable.key, environment_scope: 'production') }

          it 'does not update the variable' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(variable.reload.environment_scope).to eq('*')
          end
        end
      end

      context ':group_scoped_ci_variables licensed feature is not available' do
        let(:scoped_variables_available) { false }

        it 'does not update the variable' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(variable.reload.environment_scope).to eq('*')
          expect(json_response['environment_scope']).to eq('*')
        end
      end
    end
  end
end
