# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a timelog', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:author) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:time_spent) { '1h' }

  let(:current_user) { nil }
  let(:users_container) { group }

  context 'when issuable is an Epic' do
    let_it_be(:issuable) { create(:epic, group: group) }

    it_behaves_like 'issuable does not support timelog creation mutation'
  end
end
