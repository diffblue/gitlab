# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath)', feature_category: :product_analytics do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  context 'with trackingKey' do
    let_it_be(:query) do
      %(
      query {
        project(fullPath: "#{project.full_path}") {
          trackingKey
        }
      }
    )
    end

    subject do
      GitlabSchema.execute(query, context: { current_user: user }).as_json.dig('data', 'project', 'trackingKey')
    end

    using RSpec::Parameterized::TableSyntax

    where(:licensed, :enabled, :user_role, :jitsu_key, :output) do
      true  | true  | :developer | 'key' | 'key'
      true  | false | :developer | 'key' | nil
      false | true  | :developer | 'key' | nil
      false | false | :developer | 'key' | nil
      true  | true  | :maintainer | 'key' | 'key'
      true  | false | :maintainer | 'key' | nil
      false | true  | :maintainer | 'key' | nil
      false | false | :maintainer | 'key' | nil
      true  | true  | :owner | 'key' | 'key'
      true  | false | :owner | 'key' | nil
      false | true  | :owner | 'key' | nil
      false | false | :owner | 'key' | nil
      true  | true  | :guest | 'key' | nil
      true  | false | :guest | 'key' | nil
      false | true  | :guest | 'key' | nil
      false | false | :guest | 'key' | nil
    end

    with_them do
      before do
        stub_licensed_features(product_analytics: licensed)
        stub_feature_flags(product_analytics_dashboards: enabled)
        project.add_role(user, user_role)
        project.project_setting.update!(jitsu_key: jitsu_key)
        project.reload
      end

      it { is_expected.to eq(output) }
    end
  end

  context 'with productAnalyticsState' do
    let_it_be(:query) do
      %(
      query {
        project(fullPath: "#{project.full_path}") {
          id
          productAnalyticsState
        }
      }
    )
    end

    shared_examples_for 'queries state successfully' do
      it 'will query state correctly' do
        expect_next_instance_of(::ProductAnalytics::CubeDataQueryService) do |instance|
          expect(instance).to receive(:execute).and_return(
            ServiceResponse.success(
              message: 'test success',
              payload: {
                'results' => [{ 'data' => [{ 'TrackedEvents.count' => 1 }] }]
              }))
        end

        expect(subject.dig('data', 'project', 'productAnalyticsState')).to eq('COMPLETE')
      end
    end

    before do
      project.add_developer(user)

      stub_application_setting(product_analytics_enabled?: true)
      stub_licensed_features(product_analytics: true)
      stub_feature_flags(product_analytics_dashboards: true)
      stub_feature_flags(product_analytics_snowplow_support: false)

      allow_next_instance_of(ProjectSetting) do |instance|
        allow(instance).to receive(:jitsu_key).and_return('test key')
      end

      allow_next_instance_of(Resolvers::ProductAnalytics::StateResolver) do |instance|
        allow(instance).to receive(:initializing?).and_return(false)
      end
    end

    subject do
      GitlabSchema.execute(query, context: { current_user: user })
                  .as_json
    end

    it_behaves_like 'queries state successfully'

    it 'will pass through Cube API errors' do
      expect_next_instance_of(::ProductAnalytics::CubeDataQueryService) do |instance|
        expect(instance).to receive(:execute).and_return(
          ServiceResponse.error(
            message: 'Error',
            reason: :bad_gateway,
            payload: {
              'error' => 'Test Error'
            }))
      end

      expect(subject.dig('errors', 0, 'message')).to eq('Error from Cube API: Test Error')
    end

    it 'will query state when Cube DB does not exist' do
      expect_next_instance_of(::ProductAnalytics::CubeDataQueryService) do |instance|
        expect(instance).to receive(:execute).and_return(
          ServiceResponse.error(
            message: '404 Clickhouse Database Not Found', reason: :not_found))
      end

      expect(subject.dig('data', 'project', 'productAnalyticsState')).to eq('WAITING_FOR_EVENTS')
    end

    it 'will pass through Cube API connection errors' do
      expect_next_instance_of(::ProductAnalytics::CubeDataQueryService) do |instance|
        expect(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Connection Error'))
      end

      expect(subject.dig('errors', 0, 'message')).to eq('Error from Cube API: Connection Error')
    end

    context 'with snowplow enabled' do
      before do
        stub_feature_flags(product_analytics_snowplow_support: true)
        allow_next_instance_of(ProjectSetting) do |instance|
          allow(instance).to receive(:product_analytics_instrumentation_key).and_return('test key')
        end
      end

      it_behaves_like 'queries state successfully'
    end
  end
end
