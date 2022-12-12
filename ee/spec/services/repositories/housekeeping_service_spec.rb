# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::HousekeepingService, feature_category: :source_code_management do
  it_behaves_like 'housekeeps repository' do
    let_it_be(:resource) { create(:group_wiki) }
  end
end
