# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::SecondaryUsageData, :geo, type: :model, feature_category: :geo_replication do
  subject { create(:geo_secondary_usage_data) }

  let(:prometheus_client) { Gitlab::PrometheusClient.new('http://localhost:9090') }

  it 'is valid' do
    expect(subject).to be_valid
  end

  it 'cannot have undefined fields in the payload' do
    subject.payload['nope_does_not_exist'] = 'whatever'
    expect(subject).not_to be_valid
  end

  shared_examples_for 'a payload count field' do |field|
    it "defines #{field} as a method" do
      expect(subject.methods).to include(field.to_sym)
    end

    it "does not allow #{field} to be a string" do
      subject.payload[field] = 'a string'
      expect(subject).not_to be_valid
    end

    it "allows #{field} to be nil" do
      subject.payload[field] = nil
      expect(subject).to be_valid
    end

    it "may not define #{field} in the payload json" do
      subject.payload.except!(field)
      expect(subject).to be_valid
    end
  end

  Geo::SecondaryUsageData::PAYLOAD_COUNT_FIELDS.each do |field|
    describe "##{field}" do
      it_behaves_like 'a payload count field', field
    end
  end

  describe '#update_metrics!' do
    let(:new_data) { double(described_class) }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:with_prometheus_client).and_yield(prometheus_client)
      end

      allow(prometheus_client).to receive(:query).and_return([])
    end

    shared_examples 'update specific metric' do |metric, query|
      it 'gets metrics from prometheus' do
        expected_result = 48
        allow(prometheus_client).to receive(:query).with(query).and_return([{ "value" => [1614029769.82, expected_result.to_s] }])

        expect do
          described_class.update_metrics!
        end.to change { described_class.count }.by(1)

        expect(described_class.last).to be_valid
        expect(described_class.last.payload[metric]).to eq(expected_result)
      end

      it 'returns nil if metric is unavailable' do
        allow(prometheus_client).to receive(:query).with(query).and_return([])

        expect do
          described_class.update_metrics!
        end.to change { described_class.count }.by(1)

        expect(described_class.last).to be_valid
        expect(described_class.last.payload[metric]).to be_nil
      end

      it 'returns nil if it cannot reach prometheus' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:with_prometheus_client).and_return(nil)
        end

        expect do
          described_class.update_metrics!
        end.to change { described_class.count }.by(1)

        expect(described_class.last).to be_valid
        expect(described_class.last.payload[metric]).to be_nil
      end
    end

    context 'metric git_fetch_event_count_weekly' do
      it_behaves_like 'update specific metric', 'git_fetch_event_count_weekly', Geo::SecondaryUsageData::GIT_FETCH_EVENT_COUNT_WEEKLY_QUERY
    end

    context 'metric git_push_event_count_weekly' do
      it_behaves_like 'update specific metric', 'git_push_event_count_weekly', Geo::SecondaryUsageData::GIT_PUSH_EVENT_COUNT_WEEKLY_QUERY
    end

    context 'metric proxy_remote_requests_event_count_weekly' do
      it_behaves_like 'update specific metric', 'proxy_remote_requests_event_count_weekly', Geo::SecondaryUsageData::PROXY_REMOTE_REQUESTS_EVENT_COUNT_WEEKLY_QUERY
    end

    context 'metric proxy_local_requests_event_count_weekly' do
      it_behaves_like 'update specific metric', 'proxy_local_requests_event_count_weekly', Geo::SecondaryUsageData::PROXY_LOCAL_REQUESTS_EVENT_COUNT_WEEKLY_QUERY
    end
  end
end
