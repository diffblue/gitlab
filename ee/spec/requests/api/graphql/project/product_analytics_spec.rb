# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath)', feature_category: :product_analytics do
  let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }
  let_it_be(:user) { create(:user) }

  let_it_be(:events_table) { 'TrackedEvents.pageViewsCount' }

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

    where(:licensed, :enabled, :snowplow_enabled, :user_role, :jitsu_key, :snowplow_instrumentation_key, :output) do
      true  | true | false | :developer | 'jitsu_key' | nil | 'jitsu_key'
      true  | true | true | :developer | 'jitsu_key' | 'snowplow_key' | 'snowplow_key'
      true  | false | false | :developer | 'jitsu_key' | nil | nil
      false | true | false | :developer | 'jitsu_key' | nil | nil
      false | false | false | :developer | 'jitsu_key' | nil | nil
      true  | true | false | :maintainer | 'jitsu_key' | nil | 'jitsu_key'
      true  | true | true | :maintainer | 'jitsu_key' | 'snowplow_key' | 'snowplow_key'
      true  | false | false | :maintainer | 'jitsu_key' | nil | nil
      false | true | false | :maintainer | 'jitsu_key' | nil | nil
      false | false | false | :maintainer | 'jitsu_key' | nil | nil
      true  | true | false | :owner | 'jitsu_key' | nil | 'jitsu_key'
      true  | true | true | :owner | 'jitsu_key' | 'snowplow_key' | 'snowplow_key'
      true  | false | false | :owner | 'jitsu_key' | nil | nil
      false | true | false | :owner | 'jitsu_key' | nil | nil
      false | false | false | :owner | 'jitsu_key' | nil | nil
      true  | true | false | :guest | 'jitsu_key' | nil | nil
      true  | false | false | :guest | 'jitsu_key' | nil | nil
      false | true | false | :guest | 'jitsu_key' | nil | nil
      false | false | false | :guest | 'jitsu_key' | nil | nil
    end

    with_them do
      before do
        stub_licensed_features(product_analytics: licensed)
        stub_feature_flags(product_analytics_dashboards: enabled, product_analytics_snowplow_support: snowplow_enabled)
        project.add_role(user, user_role)
        project.project_setting.update!(jitsu_key: jitsu_key)
        project.project_setting.update!(product_analytics_instrumentation_key: snowplow_instrumentation_key)
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
                'results' => [{ 'data' => [{ events_table => 1 }] }]
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
      let_it_be(:events_table) { 'SnowplowTrackedEvents.pageViewsCount' }

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
