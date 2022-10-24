# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::DoraMetricsResolver, time_travel_to: '2021-05-01' do
  include GraphqlHelpers

  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_refind(:project) { create(:project, group: group) }
  let_it_be(:production) { create(:environment, :production, project: project) }
  let_it_be(:staging) { create(:environment, :staging, project: project) }

  let(:current_user) { reporter }
  let(:args) { { metric: 'deployment_frequency' } }

  before_all do
    group.add_guest(guest)
    group.add_reporter(reporter)

    create(:dora_daily_metrics, deployment_frequency: 20, lead_time_for_changes_in_seconds: nil, environment: production, date: '2020-01-01')
    create(:dora_daily_metrics, deployment_frequency: 19, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-01-01')
    create(:dora_daily_metrics, deployment_frequency: 18, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-03-01')
    create(:dora_daily_metrics, deployment_frequency: 17, lead_time_for_changes_in_seconds: 99.0, environment: production, date: '2021-04-01')
    create(:dora_daily_metrics, deployment_frequency: 16, lead_time_for_changes_in_seconds: 98.0, environment: production, date: '2021-04-02')
    create(:dora_daily_metrics, deployment_frequency: 15, lead_time_for_changes_in_seconds: 97.0, environment: production, date: '2021-04-03')
    create(:dora_daily_metrics, deployment_frequency: 14, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-04-04')
    create(:dora_daily_metrics, deployment_frequency: 13, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-04-05')
    create(:dora_daily_metrics, deployment_frequency: 12, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-04-06')
    create(:dora_daily_metrics, deployment_frequency: nil, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-04-07')
    create(:dora_daily_metrics, deployment_frequency: 11, lead_time_for_changes_in_seconds: nil, environment: production, date: '2021-05-06')

    create(:dora_daily_metrics, deployment_frequency: 10, lead_time_for_changes_in_seconds: nil, environment: staging, date: '2021-04-01')
    create(:dora_daily_metrics, deployment_frequency: nil, lead_time_for_changes_in_seconds: 99.0, environment: staging, date: '2021-04-02')
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  shared_examples 'dora metrics' do
    describe '#resolve' do
      context 'when the current users does not have access to query DORA metrics' do
        let(:current_user) { guest }

        it 'returns no metrics' do
          expect(resolve_metrics).to be_nil
        end
      end

      context 'when DORA metrics are not licensed' do
        before do
          stub_licensed_features(dora4_analytics: false)
        end

        it 'returns no metrics' do
          expect(resolve_metrics).to be_nil
        end
      end

      context 'with metric: "deployment_frequency"' do
        let(:args) { { metric: 'deployment_frequency' } }

        it 'returns metrics from production for the last 3 months from the production environment, grouped by day' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-03-01', 'value' => 18 },
              { 'date' => '2021-04-01', 'value' => 17 },
              { 'date' => '2021-04-02', 'value' => 16 },
              { 'date' => '2021-04-03', 'value' => 15 },
              { 'date' => '2021-04-04', 'value' => 14 },
              { 'date' => '2021-04-05', 'value' => 13 },
              { 'date' => '2021-04-06', 'value' => 12 },
              { 'date' => '2021-04-07', 'value' => nil }
            ])
        end
      end

      context 'with interval: "daily"' do
        let(:args) { { metric: 'deployment_frequency', interval: 'daily' } }

        it 'returns the metrics grouped by day (the default)' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-03-01', 'value' => 18 },
              { 'date' => '2021-04-01', 'value' => 17 },
              { 'date' => '2021-04-02', 'value' => 16 },
              { 'date' => '2021-04-03', 'value' => 15 },
              { 'date' => '2021-04-04', 'value' => 14 },
              { 'date' => '2021-04-05', 'value' => 13 },
              { 'date' => '2021-04-06', 'value' => 12 },
              { 'date' => '2021-04-07', 'value' => nil }
            ])
        end
      end

      context 'with interval: "monthly"' do
        let(:args) { { metric: 'deployment_frequency', interval: 'monthly' } }

        it 'returns the metrics grouped by month' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-03-01', 'value' => 18 },
              { 'date' => '2021-04-01', 'value' => 87 }
            ])
        end
      end

      context 'with interval: "all"' do
        let(:args) { { metric: 'deployment_frequency', interval: 'all' } }

        it 'returns the metrics grouped into a single bucket with a nil date' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => nil, 'value' => 105 }
            ])
        end
      end

      context 'with a start_date' do
        let(:args) { { metric: 'deployment_frequency', start_date: '2021-04-03'.to_datetime } }

        it 'returns metrics for data on or after the provided date' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-04-03', 'value' => 15 },
              { 'date' => '2021-04-04', 'value' => 14 },
              { 'date' => '2021-04-05', 'value' => 13 },
              { 'date' => '2021-04-06', 'value' => 12 },
              { 'date' => '2021-04-07', 'value' => nil }
            ])
        end
      end

      context 'with an end_date' do
        let(:args) { { metric: 'deployment_frequency', end_date: '2021-04-03'.to_datetime } }

        it 'returns metrics for data on or before the provided date' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-03-01', 'value' => 18 },
              { 'date' => '2021-04-01', 'value' => 17 },
              { 'date' => '2021-04-02', 'value' => 16 },
              { 'date' => '2021-04-03', 'value' => 15 }
            ])
        end
      end

      context 'with both a start_date and an end_date' do
        let(:args) { { metric: 'deployment_frequency', start_date: '2021-04-01'.to_datetime, end_date: '2021-04-03'.to_datetime } }

        it 'returns metrics between the provided dates (inclusive)' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-04-01', 'value' => 17 },
              { 'date' => '2021-04-02', 'value' => 16 },
              { 'date' => '2021-04-03', 'value' => 15 }
            ])
        end
      end

      context 'when the requested date range is too large' do
        let(:args) { { metric: 'deployment_frequency', start_date: '2020-01-01'.to_datetime, end_date: '2021-05-01'.to_datetime } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'Date range must be shorter than 180 days.') do
            resolve_metrics
          end
        end
      end

      context 'when the start date equal to or later than the end date' do
        let(:args) { { metric: 'deployment_frequency', start_date: '2021-04-01'.to_datetime, end_date: '2021-03-01'.to_datetime } }

        it 'generates an error' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'The start date must be earlier than the end date.') do
            resolve_metrics
          end
        end
      end

      context 'with no metric parameter' do
        let(:args) { {} }

        it 'raises an error' do
          expect { resolve_metrics }.to raise_error(/wrong number of arguments/)
        end
      end

      context 'with metric: "lead_time_for_changes"' do
        let(:args) { { metric: 'lead_time_for_changes' } }

        it 'returns lead time metrics' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-03-01', 'value' => nil },
              { 'date' => '2021-04-01', 'value' => 99.0 },
              { 'date' => '2021-04-02', 'value' => 98.0 },
              { 'date' => '2021-04-03', 'value' => 97.0 },
              { 'date' => '2021-04-04', 'value' => nil },
              { 'date' => '2021-04-05', 'value' => nil },
              { 'date' => '2021-04-06', 'value' => nil },
              { 'date' => '2021-04-07', 'value' => nil }
            ])
        end

        # Testing this combination of arguments explicitly since it previously
        # caused a bug: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65653
        context 'with interval: "all"' do
          let(:args) { { metric: 'lead_time_for_changes', interval: 'all' } }

          it 'returns the metrics grouped into a single bucket with a nil date' do
            expect(resolve_metrics).to eq(
              [
                { 'date' => nil, 'value' => 98.0 }
              ])
          end
        end
      end

      context 'with multiple environment_tiers' do
        let(:args) { { metric: 'deployment_frequency', environment_tiers: %w[production staging] } }

        it 'returns metrics for all environments combined' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-03-01', 'value' => 18 },
              { 'date' => '2021-04-01', 'value' => 27 },
              { 'date' => '2021-04-02', 'value' => 16 },
              { 'date' => '2021-04-03', 'value' => 15 },
              { 'date' => '2021-04-04', 'value' => 14 },
              { 'date' => '2021-04-05', 'value' => 13 },
              { 'date' => '2021-04-06', 'value' => 12 },
              { 'date' => '2021-04-07', 'value' => nil }
            ])
        end
      end

      context 'backwards compatibility for environment_tier' do
        let(:args) { { metric: 'deployment_frequency', environment_tier: 'staging' } }

        it 'returns metrics for the staging environment' do
          expect(resolve_metrics).to eq(
            [
              { 'date' => '2021-04-01', 'value' => 10 },
              { 'date' => '2021-04-02', 'value' => nil }
            ])
        end
      end
    end
  end

  context 'when the user is querying for project-level metrics' do
    let(:obj) { project }

    it_behaves_like 'dora metrics'
  end

  context 'when the user is querying for group-level metrics' do
    let(:obj) { group }

    it_behaves_like 'dora metrics'
  end

  private

  def resolve_metrics
    context = { current_user: current_user }
    resolve(described_class, obj: obj, args: args, ctx: context, arg_style: :internal)
  end
end
