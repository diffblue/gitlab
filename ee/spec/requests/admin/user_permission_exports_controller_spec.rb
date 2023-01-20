# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UserPermissionExportsController, feature_category: :user_profile do
  let_it_be(:admin) { create(:admin) }

  subject { get admin_user_permission_exports_path(format: :csv) }

  before do
    allow(admin).to receive(:can?).and_call_original
    allow(admin).to receive(:can?).with(:export_user_permissions).and_return(authorized)
    sign_in(admin)
  end

  describe '#index', :enable_admin_mode do
    context 'when user is authorized' do
      let(:authorized) { true }

      before do
        allow(UserPermissions::ExportService).to receive(:new).and_return(export_csv_service)
      end

      context 'when successful' do
        let(:csv_data) do
          <<~CSV
          Username,Email,Type,Path,Access,Last Activity
          alvina,alvina@test.com,Group,gitlab-org,Developer,2020-12-18
          jasper,jasper@test.com,Project,gitlab-org/www,Maintainer,2020-12-16
          CSV
        end

        let(:export_csv_service) do
          instance_spy(UserPermissions::ExportService, csv_data: ServiceResponse.success(payload: csv_data))
        end

        it 'responds with :ok', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8; header=present')
        end

        it 'invokes the Export Service' do
          subject

          expect(export_csv_service).to have_received(:csv_data)
        end

        it 'has the appropriate data' do
          subject

          expect(csv_response).to eq(
            [
              [
                'Username',
                'Email',
                'Type',
                'Path',
                'Access',
                'Last Activity'
              ],
              %w(
                alvina
                alvina@test.com
                Group
                gitlab-org
                Developer
                2020-12-18
              ),
              %w(
                jasper
                jasper@test.com
                Project
                gitlab-org/www
                Maintainer
                2020-12-16
              )
            ])
        end
      end

      context 'when Export fails' do
        let(:export_csv_service) do
          instance_spy(UserPermissions::ExportService, csv_data: ServiceResponse.error(message: 'Something went wrong!'))
        end

        it 'responds appropriately', :aggregate_failures do
          subject

          expect(flash[:alert]).to eq 'Failed to generate report, please try again after sometime'
          expect(response).to redirect_to(admin_users_path)
        end
      end
    end

    context 'when user is unauthorised' do
      let(:authorized) { false }

      it 'responds with :not_found' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def csv_response
      CSV.parse(response.body)
    end
  end
end
