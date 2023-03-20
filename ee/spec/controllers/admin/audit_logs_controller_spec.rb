# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AuditLogsController, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:admin) { create(:admin) }

  describe 'GET #index' do
    before do
      sign_in(admin)
    end

    context 'licensed' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      context 'pagination' do
        it 'paginates audit events, without casting a count query' do
          create(:user_audit_event, created_at: 5.days.ago)

          serializer = instance_spy(AuditEventSerializer)
          allow(AuditEventSerializer).to receive(:new).and_return(serializer)

          get :index, params: { 'entity_type': 'User' }

          expect(serializer).to have_received(:represent).with(kind_of(Kaminari::PaginatableWithoutCount))
        end
      end

      it_behaves_like 'tracking unique visits', :index do
        let(:request_params) { { 'entity_type': 'User' } }
        let(:target_id) { 'i_compliance_audit_events' }
      end

      it 'tracks search event', :snowplow do
        get :index

        expect_snowplow_event(
          category: 'Admin::AuditLogsController',
          action: 'search_audit_event',
          user: admin
        )
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject(:index_request) { get :index }

        let(:category) { 'Admin::AuditLogsController' }
        let(:action) { 'visit_instance_compliance_audit_events' }
        let(:label) { 'redis_hll_counters.compliance.compliance_total_unique_counts_monthly' }
        let(:property) { 'i_compliance_audit_events' }
        let(:user) { admin }
        let(:project) { nil }
        let(:namespace) { nil }
        let(:context) do
          [
            ::Gitlab::Tracking::ServicePingContext
              .new(data_source: :redis_hll, event: 'i_compliance_audit_events')
              .to_context
          ]
        end
      end

      context 'when invalid date' do
        where(:created_before, :created_after) do
          'invalid-date' | nil
          nil            | true
          '2021-13-10'   | nil
          nil            | '2021-02-31'
          '2021-03-31'   | '2021-02-31'
        end

        with_them do
          it 'returns an error' do
            get :index, params: { 'created_before': created_before, 'created_after': created_after }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(flash[:alert]).to eq 'Invalid date format. Please use UTC format as YYYY-MM-DD'
          end
        end
      end

      context 'when date range is greater than limit' do
        subject { get :index, params: { 'created_before': created_before, 'created_after': created_after } }

        it_behaves_like 'a date range error is returned'
      end
    end

    context 'by user' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      it 'finds the user by id when provided with a entity_id' do
        allow(User).to receive(:find_by_id).and_return(admin)

        get :index, params: { 'entity_type': 'User', 'entity_id': '1' }

        expect(User).to have_received(:find_by_id).with('1')
      end

      it 'finds the user by username when provided with a entity_username' do
        allow(User).to receive(:find_by_username).and_return(admin)

        get :index, params: { 'entity_type': 'User', 'entity_username': 'abc' }

        # find_by_username gets called in thee controller and in the AuditEvent model
        expect(User).to have_received(:find_by_username).twice.with('abc')
      end
    end
  end
end
