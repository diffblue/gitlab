# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AuditEventsController, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:auditor) { create(:user, auditor: true) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:events) { create_list(:group_audit_event, 5, entity_id: group.id) }

  describe 'GET #index' do
    let(:sort) { nil }
    let(:entity_type) { nil }
    let(:entity_id) { nil }

    shared_context 'when audit_events feature is available' do
      let(:level) { Gitlab::Audit::Levels::Group.new(group: group) }
      let(:audit_events_params) { ActionController::Parameters.new(sort: '', entity_type: '', entity_id: '', created_after: Date.current.beginning_of_month, created_before: Date.current.end_of_day).permit! }

      before do
        stub_licensed_features(audit_events: true)

        allow(Gitlab::Audit::Levels::Group).to receive(:new).and_return(level)
        allow(AuditEventFinder).to receive(:new).and_call_original
      end

      shared_examples 'AuditEventFinder params' do
        it 'has the correct params' do
          request

          expect(AuditEventFinder).to have_received(:new).with(
            level: level, params: audit_events_params
          )
        end
      end

      it 'renders index with 200 status code' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end

      context 'invokes AuditEventFinder with correct arguments' do
        it_behaves_like 'AuditEventFinder params'
      end

      context 'author' do
        context 'when no author entity type is specified' do
          it_behaves_like 'AuditEventFinder params'
        end

        context 'when the author entity type is specified' do
          let(:entity_type) { 'Author' }
          let(:entity_id) { 1 }
          let(:audit_events_params) { ActionController::Parameters.new(sort: '', author_id: '1', created_after: Date.current.beginning_of_month, created_before: Date.current.end_of_day).permit! }

          it_behaves_like 'AuditEventFinder params'
        end
      end

      context 'ordering' do
        shared_examples 'orders by id descending' do
          it 'orders by id descending' do
            request

            actual_event_ids = assigns(:events).map { |event| event[:id] }
            expected_event_ids = events.map(&:id).reverse

            expect(actual_event_ids).to eq(expected_event_ids)
          end
        end

        context 'when no sort order is specified' do
          it_behaves_like 'orders by id descending'
        end

        context 'when sorting by latest events first' do
          let(:sort) { 'created_desc' }

          it_behaves_like 'orders by id descending'
        end

        context 'when sorting by oldest events first' do
          let(:sort) { 'created_asc' }

          it 'orders by id ascending' do
            request

            actual_event_ids = assigns(:events).map { |event| event[:id] }
            expected_event_ids = events.map(&:id)

            expect(actual_event_ids).to eq(expected_event_ids)
          end
        end

        context 'when sorting by an unsupported sort order' do
          let(:sort) { 'FOO' }

          it_behaves_like 'orders by id descending'
        end
      end

      context 'pagination' do
        it 'sets instance variables' do
          request

          expect(assigns(:is_last_page)).to be(true)
        end

        it 'paginates audit events, without casting a count query' do
          serializer = instance_spy(AuditEventSerializer)
          allow(AuditEventSerializer).to receive(:new).and_return(serializer)

          request

          expect(serializer).to have_received(:represent).with(kind_of(Kaminari::PaginatableWithoutCount))
        end
      end

      it 'tracks search event', :snowplow do
        request

        expect_snowplow_event(
          category: 'Groups::AuditEventsController',
          action: 'search_audit_event',
          user: client,
          namespace: group
        )
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject(:controller_request) { request }

        let(:category) { 'Groups::AuditEventsController' }
        let(:action) { 'visit_group_compliance_audit_events' }
        let(:label) { 'redis_hll_counters.compliance.compliance_total_unique_counts_monthly' }
        let(:property) { 'g_compliance_audit_events' }
        let(:user) { client }
        let(:namespace) { group }
        let(:context) { [::Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: 'g_compliance_audit_events').to_context] }
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
            get :index, params: { group_id: group.to_param, 'created_before': created_before, 'created_after': created_after }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(flash[:alert]).to eq 'Invalid date format. Please use UTC format as YYYY-MM-DD'
          end
        end
      end

      context 'when date range is greater than limit' do
        subject { get :index, params: { group_id: group.to_param, 'created_before': created_before, 'created_after': created_after } }

        it_behaves_like 'a date range error is returned'
      end
    end

    context 'when authorized owner' do
      before do
        group.add_owner(owner)
        sign_in(owner)
      end

      let(:client) { owner }

      context do
        let(:request) do
          get :index, params: { group_id: group.to_param, sort: sort, entity_type: entity_type, entity_id: entity_id }
        end

        it_behaves_like 'when audit_events feature is available'
      end

      it_behaves_like 'tracking unique visits', :index do
        let(:request_params) { { group_id: group.to_param, sort: sort, entity_type: entity_type, entity_id: entity_id } }
        let(:target_id) { 'g_compliance_audit_events' }
      end
    end

    context 'when authorized auditor' do
      before do
        sign_in(auditor)
      end

      let(:client) { auditor }

      context do
        let(:request) do
          get :index, params: { group_id: group.to_param, sort: sort, entity_type: entity_type, entity_id: entity_id }
        end

        it_behaves_like 'when audit_events feature is available'
      end

      it_behaves_like 'tracking unique visits', :index do
        let(:request_params) { { group_id: group.to_param, sort: sort, entity_type: entity_type, entity_id: entity_id } }
        let(:target_id) { 'g_compliance_audit_events' }
      end
    end

    context 'unauthorized' do
      let(:request) do
        get :index, params: { group_id: group.to_param, sort: sort, entity_type: entity_type, entity_id: entity_id }
      end

      before do
        stub_licensed_features(audit_events: true)
        sign_in(user)
      end

      it 'renders 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
