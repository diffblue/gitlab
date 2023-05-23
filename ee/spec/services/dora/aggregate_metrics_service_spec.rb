# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::AggregateMetricsService, feature_category: :value_stream_management do
  let(:service) do
    described_class.new(
      container: container,
      current_user: user,
      params: params.reverse_merge({ start_date: Date.parse('2022-01-20'), end_date: Date.parse('2022-03-03') })
    )
  end

  let(:days_in_january) { 12 }
  let(:days_in_february) { 28 }
  let(:days_in_march) { 3 }
  let(:total_days) { days_in_january + days_in_february + days_in_march }

  around do |example|
    freeze_time do
      example.run
    end
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples_for 'request failure' do
      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(message)
        expect(subject[:http_status]).to eq(http_status)
      end
    end

    shared_examples_for 'correct validations' do
      context 'when data range is too wide' do
        let(:extra_params) { { start_date: 1.year.ago.to_date, end_date: Date.today } }

        it_behaves_like 'request failure' do
          let(:message) { "Date range must be shorter than #{described_class::MAX_RANGE.in_days.to_i} days." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when start date is later than end date' do
        let(:extra_params) { { start_date: Date.today, end_date: 1.year.ago.to_date } }

        it_behaves_like 'request failure' do
          let(:message) { 'The start date must be earlier than the end date.' }
          let(:http_status) { :bad_request }
        end
      end

      context 'when interval is invalid' do
        let(:extra_params) { { interval: 'unknown' } }

        it_behaves_like 'request failure' do
          let(:message) { "The interval must be one of #{::Dora::DailyMetrics::AVAILABLE_INTERVALS.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when metrics is invalid' do
        let(:extra_params) { { metrics: ['unknown'] } }

        it_behaves_like 'request failure' do
          let(:message) { "The metric must be one of #{::Dora::DailyMetrics::AVAILABLE_METRICS.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when params is empty' do
        let(:params) { {} }

        it_behaves_like 'request failure' do
          let(:message) { "The metric must be one of #{::Dora::DailyMetrics::AVAILABLE_METRICS.join(',')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when environment tiers are invalid' do
        let(:extra_params) { { environment_tiers: ['unknown'] } }

        it_behaves_like 'request failure' do
          let(:message) { "The environment tiers must be from #{Environment.tiers.keys.join(', ')}." }
          let(:http_status) { :bad_request }
        end
      end

      context 'when guest user' do
        let(:user) { guest }

        it_behaves_like 'request failure' do
          let(:message) { 'You do not have permission to access dora metrics.' }
          let(:http_status) { :unauthorized }
        end
      end
    end

    context 'when container is project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:production) { create(:environment, :production, project: project) }
      let_it_be(:staging) { create(:environment, :staging, project: project) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:guest) { create(:user) }

      let(:container) { project }
      let(:user) { maintainer }
      let(:metric) { 'deployment_frequency' }
      let(:params) { { metrics: [metric] }.merge(extra_params) }
      let(:extra_params) { {} }

      before_all do
        project.add_maintainer(maintainer)
        project.add_guest(guest)

        create(:dora_daily_metrics, deployment_frequency: 2, environment: production, date: Date.parse('2022-01-25'))
        create(:dora_daily_metrics, deployment_frequency: 5, environment: production, date: Date.parse('2022-01-28'))
        create(:dora_daily_metrics, deployment_frequency: 9, environment: production, date: Date.parse('2022-02-07'))
        create(:dora_daily_metrics, deployment_frequency: 1, environment: production, date: Date.parse('2022-03-01'))

        create(:dora_daily_metrics, deployment_frequency: 1, environment: staging, date: Date.parse('2022-02-05'))
      end

      before do
        stub_licensed_features(dora4_analytics: true)
      end

      it_behaves_like 'correct validations'

      it 'returns the aggregated data' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:data]).to eq([
          { 'date' => Date.parse('2022-01-25'), metric => 2 },
          { 'date' => Date.parse('2022-01-28'), metric => 5 },
          { 'date' => Date.parse('2022-02-07'), metric => 9 },
          { 'date' => Date.parse('2022-03-01'), metric => 1 }
        ])
      end

      context 'when interval is monthly' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_MONTHLY } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to eq([
            { 'date' => Date.parse('2022-01-01'), 'deployment_count' => 7, metric => 7.fdiv(days_in_january) },
            { 'date' => Date.parse('2022-02-01'), 'deployment_count' => 9, metric => 9.fdiv(days_in_february) },
            { 'date' => Date.parse('2022-03-01'), 'deployment_count' => 1, metric => 1.fdiv(days_in_march) }
          ])
        end
      end

      context 'when interval is all' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_ALL } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)

          expect(subject[:data]).to match([{ 'date' => nil, 'deployment_count' => 17, metric => 17.fdiv(total_days) }])
        end
      end

      context 'when environment tiers are changed' do
        let(:extra_params) { { environment_tiers: ['staging'] } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to eq([{ 'date' => Date.parse('2022-02-05'), metric => 1 }])
        end
      end

      context 'when group_project_ids parameter is given' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_ALL, group_project_ids: [1] } }

        it_behaves_like 'request failure' do
          let(:message) { 'The group_project_ids parameter is only allowed for a group' }
          let(:http_status) { :bad_request }
        end
      end
    end

    context 'when container is a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project_1) { create(:project, group: group) }
      let_it_be(:project_2) { create(:project, group: group) }
      let_it_be(:production_1) { create(:environment, :production, project: project_1) }
      let_it_be(:production_2) { create(:environment, :production, project: project_2) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:guest) { create(:user) }

      let(:container) { group }
      let(:user) { maintainer }
      let(:metric) { 'deployment_frequency' }
      let(:params) { { metrics: [metric] }.merge(extra_params) }
      let(:extra_params) { {} }

      before_all do
        group.add_maintainer(maintainer)
        group.add_guest(guest)

        create(:dora_daily_metrics, deployment_frequency: 2, environment: production_1, date: Date.parse('2022-01-25'))
        create(:dora_daily_metrics, deployment_frequency: 1, environment: production_2, date: Date.parse('2022-02-05'))
      end

      before do
        stub_licensed_features(dora4_analytics: true)
      end

      it_behaves_like 'correct validations'

      it 'returns the aggregated data' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:data]).to eq([
          { 'date' => Date.parse('2022-01-25'), metric => 2 },
          { 'date' => Date.parse('2022-02-05'), metric => 1 }
        ])
      end

      context 'when interval is monthly' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_MONTHLY } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to eq([
            { 'date' => Date.parse('2022-01-01'), 'deployment_count' => 2, metric => 2.fdiv(days_in_january) },
            { 'date' => Date.parse('2022-02-01'), 'deployment_count' => 1, metric => 1.fdiv(days_in_february) }
          ])
        end
      end

      context 'when interval is all' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_ALL } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to match([{ 'date' => nil, 'deployment_count' => 3, metric => 3.fdiv(total_days) }])
        end
      end

      context 'when group_project_ids parameter is given' do
        let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_ALL, group_project_ids: [project_2.id] } }

        it 'returns the aggregated data' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to match([{ 'date' => nil, 'deployment_count' => 1, metric => 1.fdiv(total_days) }])
        end
      end
    end

    context 'when container is nil' do
      let(:container) { nil }
      let(:user) { nil }
      let(:params) { {} }

      it_behaves_like 'request failure' do
        let(:message) { 'Container must be a project or a group.' }
        let(:http_status) { :bad_request }
      end
    end
  end

  describe '#execute_without_authorization' do
    context 'runs the service without authorization' do
      subject { service.execute_without_authorization }

      context 'when passing a non-ultimate group' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:production) { create(:environment, :production, project: project) }
        let_it_be(:maintainer) { create(:user) }

        let(:container) { group }
        let(:user) { maintainer }
        let(:metric) { 'deployment_frequency' }
        let(:params) { { environment_tiers: ['production'], interval: 'all', metrics: [metric] } }

        before do
          group.add_maintainer(maintainer)

          create(:dora_daily_metrics, deployment_frequency: 2, environment: production, date: Date.parse('2022-03-02'))

          stub_licensed_features(dora4_analytics: false)
        end

        it 'loads the deployment frequency metrics' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:data]).to match([{ 'date' => nil, 'deployment_count' => 2, metric => 2.fdiv(total_days) }])
        end
      end
    end
  end
end
