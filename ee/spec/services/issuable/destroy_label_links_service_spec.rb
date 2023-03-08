# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuable::DestroyLabelLinksService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:target) { create(:epic) }

    it_behaves_like 'service deleting label links of an issuable'
  end
end
