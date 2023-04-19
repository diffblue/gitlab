# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Set project compliance framework', feature_category: :product_analytics do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:mutation) do
    graphql_mutation(:project_initialize_product_analytics,
                     { projectPath: project.full_path },
                     'project { id }, errors')
  end

  def mutation_response
    graphql_mutation_response(:project_initialize_product_analytics)
  end

  describe '#resolve' do
    context 'when product analytics is enabled' do
      before do
        stub_licensed_features(product_analytics: true)
        stub_feature_flags(product_analytics_snowplow_support: false)
        stub_application_setting(product_analytics_enabled: true)
      end

      context 'when user is a project maintainer' do
        before do
          project.add_maintainer(current_user)
        end

        it_behaves_like 'a working GraphQL mutation'

        it 'enqueues the InitializeAnalyticsWorker' do
          expect(::ProductAnalytics::InitializeAnalyticsWorker).to receive(:perform_async).with(project.id).once

          post_graphql_mutation(mutation, current_user: current_user)
        end

        context 'when an initialization is already in progress' do
          before do
            Gitlab::Redis::SharedState.with do |redis|
              redis.set("project:#{project.id}:product_analytics_initializing", 1)
            end
          end

          it_behaves_like 'a mutation that returns errors in the response',
                          errors: ['Product analytics initialization is already in progress']
        end
      end

      context 'when user is not a project member' do
        it_behaves_like 'a mutation that returns top-level errors',
                        errors: ['The resource that you are attempting to access does not exist '\
                                 'or you don\'t have permission to perform this action']
      end
    end

    context 'when product analytics is disabled' do
      before do
        project.add_maintainer(current_user)
        stub_feature_flags(product_analytics_dashboards: false)
        stub_application_setting(product_analytics_enabled: false)
      end

      it_behaves_like 'a mutation that returns errors in the response',
                      errors: ['Product analytics is disabled']
    end
  end
end
