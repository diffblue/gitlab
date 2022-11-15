# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AuditLogReportsController, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax

  describe 'GET index' do
    let(:csv_data) do
      <<~CSV
        ID,Author Name,Action,Entity Type,Target Details
        18,タンさん,Added new project,Project,gitlab-org/awesome-rails
        19,\"Ru'by McRüb\"\"Face\",!@#$%^&*()`~ new project,Project,¯\\_(ツ)_/¯
        20,sǝʇʎq ƃuᴉpoɔǝp,",./;'[]\-= old project",Project,¯\\_(ツ)_/¯
      CSV
    end

    let(:params) do
      {
        entity_type: 'Project',
        entity_id: '789',
        created_before: '2020-09-01',
        created_after: '2020-08-01',
        author_id: '67'
      }
    end

    let(:export_csv_service) { instance_spy(AuditEvents::ExportCsvService, csv_data: csv_data) }

    subject { get :index, params: params, as: :csv }

    context 'when user has access' do
      let_it_be(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)

          allow(AuditEvents::ExportCsvService).to receive(:new).and_return(export_csv_service)
        end

        it 'invokes CSV export service with correct arguments' do
          expected_params = {
            entity_type: 'Project',
            entity_id: '789',
            created_before: Date.parse('2020-09-01').end_of_day,
            created_after: '2020-08-01',
            author_id: '67'
          }

          subject

          expect(AuditEvents::ExportCsvService).to have_received(:new).with(expected_params.with_indifferent_access)
        end

        it 'returns success status with correct headers', :aggregate_failures do
          freeze_time do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers["Content-Length"]).to be_nil
            expect(response.headers["Cache-Control"]).to eq('private, no-store')
            expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8; header=present')
            expect(response.headers['X-Accel-Buffering']).to eq('no')
            expect(response.headers['Last-Modified']).to eq('0')
            expect(response.headers['Content-Disposition'])
              .to include("filename=\"audit-events-#{Time.current.to_i}.csv\"")
          end
        end

        it 'returns a csv file in response', :aggregate_failures do
          subject

          expect(csv_response).to eq(
            [
              ["ID", "Author Name", "Action", "Entity Type", "Target Details"],
              ["18", "タンさん", "Added new project", "Project", "gitlab-org/awesome-rails"],
              ["19", "Ru'by McRüb\"Face", "!@#$%^&*()`~ new project", "Project", "¯\\_(ツ)_/¯"],
              ["20", "sǝʇʎq ƃuᴉpoɔǝp", ",./;'[]\-= old project", "Project", "¯\\_(ツ)_/¯"]
            ])
        end

        context 'when date range params are not provided' do
          let(:params) do
            {
              entity_type: 'Project',
              entity_id: '789',
              author_id: '67'
            }
          end

          it 'passes the default date range filter to the CSV export service' do
            current_time = Time.zone.local(2020, 9, 12, 1, 4, 44)
            expected_date_range_params = {
              created_before: current_time.end_of_day,
              created_after: Date.parse('2020-09-01')
            }

            travel_to(current_time) do
              subject

              expect(AuditEvents::ExportCsvService).to have_received(:new)
                .with(hash_including(expected_date_range_params))
            end
          end
        end

        context 'when invalid date params are provided' do
          let(:params) do
            {
              created_before: created_before,
              created_after: created_after
            }
          end

          where(:created_before, :created_after) do
            'invalid-date' | nil
            nil            | true
            '2021-13-10'   | nil
            nil            | '2021-02-31'
            '2021-03-31'   | '2021-02-31'
          end

          with_them do
            it 'returns an error' do
              subject

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(flash[:alert]).to eq nil
            end
          end
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(admin_audit_log: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end

    context 'when user does not have access' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
