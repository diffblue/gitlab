# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::StagesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  context 'when params have only group_id' do
    let(:params) { { group_id: group } }
    let(:parent) { group }

    context 'when use_vsa_aggregated_tables FF is enabled' do
      it_behaves_like 'Value Stream Analytics Stages controller' do
        before do
          stub_feature_flags(use_vsa_aggregated_tables: true)
        end
      end
    end

    context 'when use_vsa_aggregated_tables FF is disabled' do
      it_behaves_like 'Value Stream Analytics Stages controller' do
        before do
          stub_feature_flags(use_vsa_aggregated_tables: false)
        end
      end
    end
  end

  context 'when params have group_id and value_stream_id' do
    let_it_be(:value_stream) { create(:cycle_analytics_group_value_stream, group: group) }

    let(:params) { { group_id: group, value_stream_id: value_stream.id } }
    let(:parent) { group }

    context 'when use_vsa_aggregated_tables FF is enabled' do
      it_behaves_like 'Value Stream Analytics Stages controller' do
        before do
          stub_feature_flags(use_vsa_aggregated_tables: true)
        end
      end
    end

    context 'when use_vsa_aggregated_tables FF is disabled' do
      it_behaves_like 'Value Stream Analytics Stages controller' do
        before do
          stub_feature_flags(use_vsa_aggregated_tables: false)
        end
      end
    end
  end
end
