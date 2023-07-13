# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a list of external audit event destinations for the instance', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:destination_1) { create(:instance_external_audit_event_destination) }
  let_it_be(:destination_2) { create(:instance_external_audit_event_destination) }

  let(:path) { %i[instance_external_audit_event_destinations nodes] }

  let!(:query) do
    graphql_query_for(
      :instance_external_audit_event_destinations
    )
  end

  shared_examples 'a request that returns no destinations' do
    it 'returns no destinations' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:instance_external_audit_event_destinations, :nodes)).to be_empty
    end
  end

  context 'when user is authenticated' do
    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when user is instance admin' do
        context 'when feature flag ff_external_audit_events is enabled' do
          it 'returns the instance external audit event destinations' do
            post_graphql(query, current_user: admin)

            verification_token_regex = /\A\w{24}\z/i

            expect(graphql_data_at(*path)).to contain_exactly(
              a_hash_including(
                'destinationUrl' => destination_1.destination_url,
                'verificationToken' => a_string_matching(verification_token_regex)
              ),
              a_hash_including(
                'destinationUrl' => destination_2.destination_url,
                'verificationToken' => a_string_matching(verification_token_regex)
              )
            )
          end

          context 'when streaming headers are also present for the destination' do
            let_it_be(:header_1) do
              create(:instance_audit_events_streaming_header,
                instance_external_audit_event_destination: destination_1)
            end

            let_it_be(:header_2) do
              create(:instance_audit_events_streaming_header,
                instance_external_audit_event_destination: destination_1)
            end

            let_it_be(:header_3) do
              create(:instance_audit_events_streaming_header,
                instance_external_audit_event_destination: destination_2)
            end

            let_it_be(:query_body) do
              <<~QUERY
              nodes {
                id
                destinationUrl
                headers {
                  nodes {
                    id
                    key
                    value
                  }
                }
              }
              QUERY
            end

            let_it_be(:headers_query) do
              graphql_query_for(
                :instance_external_audit_event_destinations, {}, query_body
              )
            end

            it 'returns the instance external audit event destinations with headers' do
              post_graphql(headers_query, current_user: admin)

              expected_response = [
                {
                  "id" => destination_2.to_gid.to_s,
                  "destinationUrl" => destination_2.destination_url,
                  "headers" => {
                    "nodes" => [
                      {
                        "id" => header_3.to_gid.to_s,
                        "key" => header_3.key,
                        "value" => header_3.value
                      }
                    ]
                  }
                },
                {
                  "id" => destination_1.to_gid.to_s,
                  "destinationUrl" => destination_1.destination_url,
                  "headers" => {
                    "nodes" => [
                      {
                        "id" => header_1.to_gid.to_s,
                        "key" => header_1.key,
                        "value" => header_1.value
                      },
                      {
                        "id" => header_2.to_gid.to_s,
                        "key" => header_2.key,
                        "value" => header_2.value
                      }
                    ]
                  }
                }
              ]

              expect(graphql_data_at(:instance_external_audit_event_destinations, :nodes))
                .to match_array(expected_response)
            end
          end

          context 'when streaming event type filters are present for the destination' do
            let_it_be(:filter_1) do
              create(:audit_events_streaming_instance_event_type_filter,
                instance_external_audit_event_destination: destination_1)
            end

            let_it_be(:filter_2) do
              create(:audit_events_streaming_instance_event_type_filter,
                instance_external_audit_event_destination: destination_1)
            end

            let_it_be(:filter_3) do
              create(:audit_events_streaming_instance_event_type_filter,
                instance_external_audit_event_destination: destination_2)
            end

            let_it_be(:query_body) do
              <<~QUERY
              nodes {
                id
                destinationUrl
                eventTypeFilters
              }
              QUERY
            end

            let_it_be(:event_filters_query) do
              graphql_query_for(
                :instance_external_audit_event_destinations, {}, query_body
              )
            end

            it 'returns the instance external audit event destinations with event type filters' do
              post_graphql(event_filters_query, current_user: admin)

              expected_response = [
                {
                  "id" => destination_2.to_gid.to_s,
                  "destinationUrl" => destination_2.destination_url,
                  "eventTypeFilters" => [filter_3.audit_event_type]
                },
                {
                  "id" => destination_1.to_gid.to_s,
                  "destinationUrl" => destination_1.destination_url,
                  "eventTypeFilters" => [filter_1.audit_event_type, filter_2.audit_event_type]
                }
              ]

              expect(graphql_data_at(:instance_external_audit_event_destinations, :nodes))
                .to match_array(expected_response)
            end
          end
        end

        context 'when feature flag ff_external_audit_events is disabled' do
          before do
            stub_feature_flags(ff_external_audit_events: false)
          end

          it_behaves_like 'a request that returns no destinations' do
            let(:current_user) { admin }
          end
        end
      end

      context 'when user is not instance admin' do
        context 'when feature flag ff_external_audit_events is enabled' do
          it_behaves_like 'a request that returns no destinations' do
            let(:current_user) { user }
          end
        end

        context 'when feature flag ff_external_audit_events is disabled' do
          before do
            stub_feature_flags(ff_external_audit_events: false)
          end

          it_behaves_like 'a request that returns no destinations' do
            let(:current_user) { user }
          end
        end
      end
    end

    context 'when feature is not licensed' do
      context 'when user is instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { admin }
        end
      end

      context 'when user is not instance admin' do
        it_behaves_like 'a request that returns no destinations' do
          let(:current_user) { user }
        end
      end
    end
  end

  context 'when user is not authenticated' do
    let(:user) { nil }

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      it_behaves_like 'a request that returns no destinations' do
        let(:current_user) { user }
      end
    end

    context 'when feature is not licensed' do
      it_behaves_like 'a request that returns no destinations' do
        let(:current_user) { user }
      end
    end
  end
end
