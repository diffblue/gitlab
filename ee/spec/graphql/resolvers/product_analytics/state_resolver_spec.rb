# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProductAnalytics::StateResolver, feature_category: :product_analytics do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: project, ctx: { current_user: user }) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    before do
      stub_licensed_features(product_analytics: true)
    end

    context 'when user has developer access' do
      before do
        project.add_developer(user)
      end

      %w[disabled create_instance loading_instance waiting_for_events complete].each do |state|
        context "when #{state}" do
          it "returns #{state}" do
            setup_for(state)
            expect(subject).to eq(state == 'disabled' ? nil : state)
          end
        end
      end

      context "when error is raised by Cube" do
        it "raises error in GraphQL output" do
          setup_for('error')
          expect(subject).to be_a(::Gitlab::Graphql::Errors::BaseError)
        end
      end

      context "when Cube DB does not exist" do
        it "returns waiting_for_events state" do
          setup_for('no_db')
          expect(subject).to eq('waiting_for_events')
        end
      end
    end

    context 'when user has guest access' do
      before do
        project.add_guest(user)
      end

      context 'in any state' do
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end

  private

  def setup_for(state)
    stub_application_setting(product_analytics_enabled?: state != 'disabled')
    allow(project).to receive(:product_analytics_enabled?).and_return(state != 'disabled')
    allow(project.project_setting).to receive(:jitsu_key).and_return(state == 'create_instance' ? nil : 'test key')
    allow(project.project_setting).to receive(:product_analytics_instrumentation_key)
                                        .and_return(state == 'create_instance' ? nil : 'test key')

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:initializing?).and_return(state == 'loading_instance')
    end

    allow_next_instance_of(::ProductAnalytics::CubeDataQueryService) do |instance|
      allow(instance).to receive(:execute).and_return(
        case state
        when 'error'
          ServiceResponse.error(
            message: 'Error',
            reason: :bad_gateway,
            payload: {
              'error' => 'Test Error'
            })
        when 'no_db'
          ServiceResponse.error(
            message: '404 Clickhouse Database Not Found',
            reason: :not_found)
        else
          ServiceResponse.success(
            message: 'test success',
            payload: {
              'results' => [{ 'data' => [{ 'TrackedEvents.count' => state == 'waiting_for_events' ? 0 : 1 }] }]
            })
        end
      )
    end
  end
end
