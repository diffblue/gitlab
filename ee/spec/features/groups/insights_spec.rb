# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Insights', feature_category: :value_stream_management do
  it_behaves_like 'Insights page' do
    let_it_be(:entity) { create(:group) }
    let(:route) { url_for([entity, :insights]) }
    let(:path) { group_insights_path(entity) }
  end
end
