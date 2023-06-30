# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::InsightsController, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }

  before do
    stub_licensed_features(insights: true, dora4_analytics: true)

    login_as(user)
  end

  describe 'GET #show' do
    it_behaves_like 'contribution analytics charts configuration' do
      let_it_be(:insights_entity) { group }

      def run_request
        get group_insights_path(
          group_id: group,
          format: :json
        )
      end
    end
  end
end
