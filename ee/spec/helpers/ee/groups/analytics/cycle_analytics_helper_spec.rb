# frozen_string_literal: true
require "spec_helper"

RSpec.describe EE::Groups::Analytics::CycleAnalyticsHelper do
  describe '#group_cycle_analytics_data' do
    let(:image_path_keys) { [:empty_state_svg_path, :no_data_svg_path, :no_access_svg_path] }
    let(:additional_data_keys) { [:default_stages] }

    subject(:group_cycle_analytics) { helper.group_cycle_analytics_data(group) }

    context 'when a group is present' do
      let(:group) { create(:group) }
      let(:api_path_keys) { [:milestones_path, :labels_path] }

      it "sets the correct data keys" do
        expect(group_cycle_analytics.keys)
          .to match_array(api_path_keys + image_path_keys + additional_data_keys)
      end
    end

    context 'when a group is not present' do
      let(:group) { nil }

      it "sets the correct data keys" do
        expect(group_cycle_analytics.keys)
          .to match_array(image_path_keys + additional_data_keys)
      end
    end
  end
end
