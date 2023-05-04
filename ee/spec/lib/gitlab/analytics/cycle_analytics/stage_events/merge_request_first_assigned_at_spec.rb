# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestFirstAssignedAt, feature_category: :value_stream_management do
  let_it_be(:event_factory) { :merge_request_assignment_event }
  let_it_be(:model_factory) { :merge_request }

  it_behaves_like 'value stream analytics event'

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:record_with_data) do
      create(:merge_request).tap do |mr|
        create(:merge_request_assignment_event, merge_request: mr)
      end
    end

    let_it_be(:record_without_data) { create(:merge_request) }
  end

  it_behaves_like 'value stream analytics first assignment event methods'
end
