# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::AuditEvents, feature_category: :audit_events do
  describe 'Unique usage tracking', :clean_gitlab_redis_shared_state do
    let_it_be(:current_user) { create(:admin) }
    let_it_be(:group) { create(:group, owner_id: current_user) }
    let_it_be(:project) { create(:project) }

    before do
      project.add_member(current_user, :maintainer)
    end

    context 'after calling all audit_events APIs as a single licensed user' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      subject do
        travel_to 8.days.ago do
          get api('/audit_events', current_user)
          get api("/groups/#{group.id}/audit_events", current_user)
          get api("/projects/#{project.id}/audit_events", current_user)
        end
      end

      it 'tracks 3 separate events' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).exactly(3).times
                                                                  .with('a_compliance_audit_events_api', values: current_user.id)
        # user activity tracking is also recorded
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
                                                                  .with('unique_active_user', values: current_user.id)
        subject
      end

      it 'reports one unique event' do
        subject

        expect(Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'a_compliance_audit_events_api', start_date: 2.months.ago, end_date: Date.current)).to eq(1)
      end
    end
  end

  describe 'GET /audit_events' do
    let(:url) { "/audit_events" }

    context 'when authenticated, as a user' do
      let(:user) { create(:user) }

      it_behaves_like '403 response' do
        let(:request) { get api(url, user) }
      end
    end

    context 'when authenticated, as an admin' do
      let_it_be(:admin) { create(:admin) }

      context 'audit events feature is not available' do
        it_behaves_like '403 response' do
          let(:request) { get api(url, admin) }
        end
      end

      context 'audit events feature is available' do
        let_it_be(:user_audit_event) { create(:user_audit_event, created_at: Date.new(2000, 1, 10)) }
        let_it_be(:project_audit_event) { create(:project_audit_event, created_at: Date.new(2000, 1, 15)) }
        let_it_be(:group_audit_event) { create(:group_audit_event, created_at: Date.new(2000, 1, 20)) }

        before do
          stub_licensed_features(admin_audit_log: true)
        end

        it 'returns 200 response' do
          get api(url, admin)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'includes the correct pagination headers' do
          audit_events_counts = AuditEvent.count

          get api(url, admin)

          expect(response).to include_pagination_headers
          expect(response.headers['X-Total']).to eq(audit_events_counts.to_s)
          expect(response.headers['X-Page']).to eq('1')
        end

        context 'parameters' do
          context 'entity_type parameter' do
            it "returns audit events of the provided entity type" do
              get api(url, admin), params: { entity_type: 'User' }

              expect(json_response.size).to eq 1
              expect(json_response.first["id"]).to eq(user_audit_event.id)
            end
          end

          context 'entity_id parameter' do
            context 'requires entity_type parameter to be present' do
              it_behaves_like '400 response' do
                let(:request) { get api(url, admin), params: { entity_id: 1 } }
              end
            end

            it 'returns audit_events of the provided entity id' do
              get api(url, admin), params: { entity_type: 'User', entity_id: user_audit_event.entity_id }

              expect(json_response.size).to eq 1
              expect(json_response.first["id"]).to eq(user_audit_event.id)
            end
          end

          context 'created_before parameter' do
            it "returns audit events created before the given parameter" do
              created_before = '2000-01-20T00:00:00.060Z'

              get api(url, admin), params: { created_before: created_before }

              expect(json_response.size).to eq 3
              expect(json_response.first["id"]).to eq(group_audit_event.id)
              expect(json_response.last["id"]).to eq(user_audit_event.id)
            end
          end

          context 'created_after parameter' do
            it "returns audit events created after the given parameter" do
              created_after = '2000-01-12T00:00:00.060Z'

              get api(url, admin), params: { created_after: created_after }

              expect(json_response.size).to eq 2
              expect(json_response.first["id"]).to eq(group_audit_event.id)
              expect(json_response.last["id"]).to eq(project_audit_event.id)
            end
          end
        end

        context 'attributes' do
          it 'exposes the right attributes' do
            get api(url, admin), params: { entity_type: 'User' }

            response = json_response.first
            details = response['details']

            expect(response["id"]).to eq(user_audit_event.id)
            expect(response["author_id"]).to eq(user_audit_event.user.id)
            expect(response["entity_id"]).to eq(user_audit_event.entity_id)
            expect(response["entity_type"]).to eq('User')
            expect(Time.parse(response["created_at"])).to be_like_time(user_audit_event.created_at)
            expect(details).to eq user_audit_event.formatted_details.with_indifferent_access
          end
        end
      end
    end

    context 'keyset pagination' do
      let_it_be(:current_user) { create(:admin) }
      let_it_be(:group) { create(:group) }
      let_it_be(:audit_event_1) { create(:group_audit_event, entity_id: group.id) }
      let_it_be(:audit_event_2) { create(:group_audit_event, entity_id: group.id) }

      it 'paginates the records correctly' do
        get api("/groups/#{group.id}/audit_events", current_user), params: { pagination: 'keyset', per_page: 1 }

        expect(response).to have_gitlab_http_status(:ok)
        records = json_response
        expect(records.size).to eq(1)
        expect(records.first['id']).to eq(audit_event_2.id)

        params_for_next_page = params_for_next_page(response)
        expect(params_for_next_page).to include('cursor')

        get api("/groups/#{group.id}/audit_events"), params: params_for_next_page

        expect(response).to have_gitlab_http_status(:ok)
        records = Gitlab::Json.parse(response.body)
        expect(records.size).to eq(1)
        expect(records.first['id']).to eq(audit_event_1.id)
      end

      def pagination_links(response)
        link = response.headers['LINK']
        return unless link

        link.split(',').map do |link|
          match = link.match(/<(?<url>.*)>; rel="(?<rel>\w+)"/)
          break nil unless match

          { url: match[:url], rel: match[:rel] }
        end.compact
      end

      def params_for_next_page(response)
        next_url = pagination_links(response).find { |link| link[:rel] == 'next' }[:url]
        Rack::Utils.parse_query(URI.parse(next_url).query)
      end

      context 'on making requests with unsupported ordering structure' do
        it 'returns error' do
          get api("/groups/#{group.id}/audit_events", current_user), params: { pagination: 'keyset', per_page: 1, order_by: 'created_at', sort: 'asc' }

          expect(response).to have_gitlab_http_status(:method_not_allowed)
          expect(json_response['error']).to eq('Keyset pagination is not yet available for this type of request')
        end
      end
    end
  end

  describe 'GET /audit_events/:id' do
    let_it_be(:user_audit_event) { create(:user_audit_event, created_at: Date.new(2000, 1, 10)) }

    let(:url) { "/audit_events/#{user_audit_event.id}" }

    context 'when authenticated, as a user' do
      let(:user) { create(:user) }

      it_behaves_like '403 response' do
        let(:request) { get api(url, user) }
      end
    end

    context 'when authenticated, as an admin' do
      let(:admin) { create(:admin) }

      context 'audit events feature is not available' do
        it_behaves_like '403 response' do
          let(:request) { get api(url, admin) }
        end
      end

      context 'audit events feature is available' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'audit event exists' do
          it 'returns 200 response' do
            get api(url, admin)

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'attributes' do
            it 'exposes the right attributes' do
              get api(url, admin)
              details = json_response['details']

              expect(json_response["id"]).to eq(user_audit_event.id)
              expect(json_response["author_id"]).to eq(user_audit_event.user.id)
              expect(json_response["entity_id"]).to eq(user_audit_event.entity_id)
              expect(json_response["entity_type"]).to eq('User')
              expect(Time.parse(json_response["created_at"])).to be_like_time(user_audit_event.created_at)
              expect(details).to eq user_audit_event.formatted_details.with_indifferent_access
            end
          end
        end

        context 'audit event does not exist' do
          it_behaves_like '404 response' do
            let(:url) { "/audit_events/10001" }
            let(:request) { get api(url, admin) }
          end
        end
      end
    end
  end
end
