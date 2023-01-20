# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stage, feature_category: :value_stream_management do
  include_examples 'value stream analytics label based stage' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:parent_in_subgroup) { create(:group, parent: parent) }
    let_it_be(:group_label) { create(:group_label, group: parent) }
    let_it_be(:parent_outside_of_group_label_scope) { create(:group) }
  end
end
