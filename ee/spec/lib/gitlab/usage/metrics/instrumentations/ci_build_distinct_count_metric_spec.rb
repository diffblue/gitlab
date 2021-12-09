# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CiBuildDistinctCountMetric do
  before_all do
    user = create(:user)
    create(:ci_build, name: 'dast')
    create(:ci_build, name: 'container_scanning', user: user)
    create(:ci_build, name: 'container_scanning', user: user)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database', options: { secure_type: 'container_scanning' } } do
    let(:expected_value) { 1 }
  end

  it 'raises an exception if secure_type option is not present' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'raises an exception if secure_type option is invalid' do
    expect { described_class.new(option: { secure_type: 'invalid_type' }) }.to raise_error(ArgumentError)
  end

  context 'with cache_start_and_finish_as called' do
    before do
      allow_next_instance_of(Gitlab::Database::BatchCounter) do |batch_counter|
        allow(batch_counter).to receive(:transaction_open?).and_return(false)
      end
    end

    it 'caches using the key name passed', :request_store, :use_clean_rails_redis_caching do
      expect(Gitlab::Cache).to receive(:fetch_once).with('metric_instrumentation/ci_build_distinct_count_user_minimum_id', any_args).and_call_original
      expect(Gitlab::Cache).to receive(:fetch_once).with('metric_instrumentation/ci_build_distinct_count_user_maximum_id', any_args).and_call_original

      described_class.new(time_frame: 'all', options: { secure_type: 'container_scanning' }).value

      expect(Rails.cache.read('metric_instrumentation/ci_build_distinct_count_user_minimum_id')).to eq(::User.minimum(:id))
      expect(Rails.cache.read('metric_instrumentation/ci_build_distinct_count_user_maximum_id')).to eq(::User.maximum(:id))
    end
  end
end
