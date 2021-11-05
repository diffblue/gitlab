# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicsHelper, type: :helper do
  include ApplicationHelper

  describe '#epic_new_app_data' do
    let(:group) { create(:group) }

    it 'returns the correct data for a new epic' do
      expected_data = {
        group_path: group.full_path,
        group_epics_path: "/groups/#{group.full_path}/-/epics",
        labels_fetch_path: "/groups/#{group.full_path}/-/labels.json?include_ancestor_groups=true&only_group_labels=true",
        labels_manage_path: "/groups/#{group.full_path}/-/labels",
        markdown_preview_path: "/groups/#{group.full_path}/preview_markdown",
        markdown_docs_path: help_page_path('user/markdown')
      }

      expect(helper.epic_new_app_data(group)).to match(hash_including(expected_data))
    end
  end

  describe '#epic_endpoint_query_params' do
    let(:endpoint_data) do
      {
        only_group_labels: true,
        include_ancestor_groups: true,
        include_descendant_groups: true
      }
    end

    it 'includes Epic specific options in JSON format' do
      opts = epic_endpoint_query_params({})

      expect(opts[:data][:endpoint_query_params]).to eq(endpoint_data.to_json)
    end

    it 'includes data provided in param' do
      opts = epic_endpoint_query_params(data: { default_param: true })

      expect(opts[:data]).to eq({ default_param: true }.merge(endpoint_query_params: endpoint_data.to_json))
    end
  end

  describe '#epic_timeframe' do
    let(:epic) { build(:epic, start_date: start_date, end_date: end_date) }

    subject { epic_timeframe(epic) }

    context 'when both dates are from the same year' do
      let(:start_date) { Date.new(2018, 7, 22) }
      let(:end_date) { Date.new(2018, 8, 15) }

      it 'returns start date with year omitted and end date with year' do
        is_expected.to eq('Jul 22 – Aug 15, 2018')
      end
    end

    context 'when both dates are from different years' do
      let(:start_date) { Date.new(2018, 7, 22) }
      let(:end_date) { Date.new(2019, 7, 22) }

      it 'returns start date with year omitted and end date with year' do
        is_expected.to eq('Jul 22, 2018 – Jul 22, 2019')
      end
    end

    context 'when only start date is present' do
      let(:start_date) { Date.new(2018, 7, 22) }
      let(:end_date) { nil }

      it 'returns start date with year' do
        is_expected.to eq('Jul 22, 2018 – No end date')
      end
    end

    context 'when only end date is present' do
      let(:start_date) { nil }
      let(:end_date) { Date.new(2018, 7, 22) }

      it 'returns end date with year' do
        is_expected.to eq('No start date – Jul 22, 2018')
      end
    end
  end
end
