# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageEntity do
  subject(:entity_json) { described_class.new(Analytics::CycleAnalytics::StagePresenter.new(stage)).as_json }

  context 'when label based event is given' do
    let(:label) { build_stubbed(:group_label, title: 'test::label') }
    let(:stage) { build_stubbed(:cycle_analytics_stage, namespace: label.group, start_event_label: label, start_event_identifier: :merge_request_label_added, end_event_identifier: :merge_request_merged) }

    it 'includes the label reference in the description' do
      expect(entity_json[:start_event_html_description]).to include('test')
      expect(entity_json[:start_event_html_description]).to include('label')
    end
  end
end
