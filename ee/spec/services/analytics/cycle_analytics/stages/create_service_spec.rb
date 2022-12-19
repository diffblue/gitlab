# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stages::CreateService do
  let_it_be(:group, refind: true) { create(:group) }
  let_it_be(:value_stream, refind: true) { create(:cycle_analytics_group_value_stream, namespace: group) }
  let_it_be(:user, refind: true) { create(:user) }

  let(:params) do
    {
      name: 'my stage',
      value_stream: value_stream,
      start_event_identifier: :merge_request_created,
      end_event_identifier: :merge_request_merged
    }
  end

  before_all do
    group.add_member(user, :reporter)
  end

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)
  end

  subject { described_class.new(parent: group, params: params, current_user: user).execute }

  it_behaves_like 'permission check for Value Stream Analytics Stage services', :cycle_analytics_for_groups

  describe 'custom stage creation' do
    context 'when service response is successful' do
      let(:stage) { subject.payload[:stage] }

      it { expect(subject).to be_success }
      it { expect(subject.http_status).to eq(:created) }
      it { expect(stage).to be_present }
      it { expect(stage).to be_persisted }
      it { expect(stage.start_event_identifier).to eq(params[:start_event_identifier].to_s) }
      it { expect(stage.end_event_identifier).to eq(params[:end_event_identifier].to_s) }
    end
  end

  context 'when params are invalid' do
    before do
      params.delete(:name)
    end

    it { expect(subject).to be_error }
    it { expect(subject.http_status).to eq(:unprocessable_entity) }
    it { expect(subject.payload[:errors].attribute_names).to eq([:name]) }
  end

  describe 'persistence of default stages' do
    let(:persisted_stages) { value_stream.stages }
    let(:customized_stages) { value_stream.stages.where(custom: true) }
    let(:default_stages) { Gitlab::Analytics::CycleAnalytics::DefaultStages.all }
    let(:expected_stage_count) { default_stages.count + customized_stages.count }

    context 'when creating custom stages' do
      it { expect(subject).to be_success }

      it 'persists all default stages' do
        subject

        expect(persisted_stages.count).to eq(expected_stage_count)
      end

      context 'when creating two custom stages' do
        before do
          described_class.new(parent: group, params: params.merge(name: 'other stage'), current_user: user).execute
        end

        it 'creates two customized stages' do
          subject

          expect(customized_stages.count).to eq(2)
        end

        it 'creates records for the default stages only once plus two customized stage records' do
          expect(group.cycle_analytics_stages.count).to eq(expected_stage_count)
        end
      end

      context 'when creating a stage for the second value stream' do
        before do
          first_value_stream = create(:cycle_analytics_group_value_stream, namespace: group)
          described_class.new(parent: group, params: params.merge(name: 'other stage', value_stream: first_value_stream), current_user: user).execute
        end

        it 'persists the new stage and the default stages for the second value streams' do
          subject

          expect(value_stream.stages.count).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size + 1)
        end
      end
    end

    context 'when params are invalid' do
      before do
        params.delete(:name)
      end

      it { expect(subject).to be_error }

      it 'skips persisting default stages on validation error' do
        expect(group.cycle_analytics_stages.count).to eq(0)
      end
    end
  end

  describe 'label based stages' do
    let(:label) { create(:group_label, group: group) }

    let(:params) do
      {
        name: 'my stage',
        start_event_identifier: :issue_label_added,
        end_event_identifier: :issue_label_removed,
        start_event_label_id: label.id,
        end_event_label_id: label.id,
        value_stream: value_stream
      }
    end

    it { expect(subject).to be_success }

    it 'persists the `start_event_label_id` and `end_event_label_id` attributes' do
      subject

      stage = subject.payload[:stage]

      expect(stage.start_event_label).to eq(label)
      expect(stage.end_event_label).to eq(label)
    end
  end

  context 'when `value_stream` is not provided' do
    before do
      params.delete(:value_stream)
    end

    let(:stage) { subject.payload[:stage] }

    it 'creates a `default` value stream object' do
      expect(stage).to be_persisted
      expect(stage.value_stream.name).to eq(Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME)
    end
  end
end
