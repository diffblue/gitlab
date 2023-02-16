# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group settings > [EE] General', feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let(:merge_requests_settings_path) { edit_group_path(sub_group) }

  it_behaves_like 'MR checks settings'
end
