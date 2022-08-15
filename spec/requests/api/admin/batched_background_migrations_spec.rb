require 'spec_helper'

RSpec.describe API::Admin::BatchedBackgroundMigrations do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unauthorized_user) { create(:user) }

  describe 'GET /admin/batched_background_migrations' do
    let!(:migration) { create(:batched_background_migration) }

    context 'when is an admin user' do
      it 'returns batched background migrations' do
        get api('/admin/batched_background_migrations', admin)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.first['id']).to eq(migration.id)
          expect(json_response.first['job_class_name']).to eq(migration.job_class_name)
          expect(json_response.first['table_name']).to eq(migration.table_name)
          expect(json_response.first['status']).to eq(migration.status_name.to_s)
          expect(json_response.first['progress']).to be_zero
        end
      end
    end

    context 'when authenticated as a non-admin user' do
      it 'returns 403' do
        get api('/admin/batched_background_migrations', unauthorized_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
