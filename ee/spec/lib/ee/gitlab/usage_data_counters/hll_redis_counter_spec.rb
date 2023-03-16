# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::HLLRedisCounter, :clean_gitlab_redis_shared_state, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  let(:entity1) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:entity2) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:entity3) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }

  let(:default_context) { 'default' }
  let(:ultimate_context) { 'ultimate' }
  let(:gold_context) { 'gold' }
  let(:invalid_context) { 'invalid' }

  let(:context_event) { 'context_event' }
  let(:other_context_event) { 'other_context_event' }

  let(:known_events) do
    [
      { name: context_event, aggregation: 'weekly' },
      { name: other_context_event, aggregation: 'weekly' }
    ].map(&:with_indifferent_access)
  end

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    # Monday 6th of June
    described_class.clear_memoization(:known_events)
    reference_time = Time.utc(2020, 6, 1)
    travel_to(reference_time) { example.run }
    described_class.clear_memoization(:known_events)
  end

  describe '.known_events' do
    let(:ce_temp_dir) { Dir.mktmpdir }
    let(:ee_temp_dir) { Dir.mktmpdir }
    let(:ce_temp_file) { Tempfile.new(%w[common .yml], ce_temp_dir) }
    let(:ee_temp_file) { Tempfile.new(%w[common .yml], ee_temp_dir) }
    let(:ce_event) do
      {
        "name" => "ce_event",
        "expiry" => 84,
        "aggregation" => "weekly"
      }
    end

    let(:ee_event) do
      {
        "name" => "ee_event",
        "expiry" => 84,
        "aggregation" => "weekly"
      }
    end

    before do
      stub_const("#{described_class}::KNOWN_EVENTS_PATH", File.expand_path('*.yml', ce_temp_dir))
      stub_const("EE::#{described_class}::EE_KNOWN_EVENTS_PATH", File.expand_path('*.yml', ee_temp_dir))
      File.open(ce_temp_file.path, "w+b") { |f| f.write [ce_event].to_yaml }
      File.open(ee_temp_file.path, "w+b") { |f| f.write [ee_event].to_yaml }
    end

    it 'returns both ee and ce events' do
      expect(described_class.known_events).to match_array [ce_event, ee_event]
    end

    after do
      ce_temp_file.unlink
      ee_temp_file.unlink
      FileUtils.remove_entry(ce_temp_dir) if Dir.exist?(ce_temp_dir)
      FileUtils.remove_entry(ee_temp_dir) if Dir.exist?(ee_temp_dir)
    end
  end

  describe '.track_event_in_context' do
    before do
      allow(described_class).to receive(:known_events).and_return(known_events)
    end

    context 'with valid context' do
      where(:entity, :event_name, :context) do
        entity1 | context_event | default_context
        entity1 | context_event | ultimate_context
        entity1 | context_event | gold_context
      end

      with_them do
        it 'increments context event counter' do
          expect(Gitlab::Redis::HLL).to receive(:add) do |kwargs|
            expect(kwargs[:key]).to match(/^#{context}\_.*/)
          end

          described_class.track_event_in_context(event_name, values: entity, context: context)
        end
      end
    end

    context 'when sending empty context' do
      it 'is not incrementing the counter' do
        expect(Gitlab::Redis::HLL).not_to receive(:add)

        described_class.track_event_in_context(context_event, values: entity1, context: '')
      end
    end
  end

  describe '.unique_events' do
    context 'with events tracked in context' do
      before do
        allow(described_class).to receive(:known_events).and_return(known_events)
        described_class.track_event_in_context(context_event, values: [entity1, entity3], context: default_context, time: 2.days.ago)
        described_class.track_event_in_context(context_event, values: entity3, context: ultimate_context, time: 2.days.ago)
        described_class.track_event_in_context(context_event, values: entity3, context: gold_context, time: 2.days.ago)
        described_class.track_event_in_context(context_event, values: entity3, context: invalid_context, time: 2.days.ago)
        described_class.track_event_in_context(context_event, values: [entity1, entity2], context: '', time: 2.weeks.ago)
      end

      subject(:unique_events) { described_class.unique_events(event_names: context_event, start_date: 4.weeks.ago, end_date: Date.current, context: context) }

      context 'with correct arguments' do
        where(:context, :value) do
          ref(:default_context)  | 2
          ref(:ultimate_context) | 1
          ref(:gold_context)     | 1
          ''                     | 0
        end

        with_them do
          it { is_expected.to eq value }
        end
      end

      context 'with invalid context' do
        let(:context) { invalid_context }
        let(:event_names) { context_event }

        it 'raise error' do
          expect { unique_events }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::InvalidContext)
        end
      end
    end
  end

  describe '.track_event' do
    before do
      allow(described_class).to receive(:known_events).and_return(known_events)
    end

    context 'with settings usage ping disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      context 'with license usage ping enabled' do
        before do
          # License.current.customer_service_enabled? == true
          create_current_license(operational_metrics_enabled: true)
        end

        it 'tracks the event' do
          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(context_event, values: entity1, time: Date.current)
        end
      end
    end
  end
end
