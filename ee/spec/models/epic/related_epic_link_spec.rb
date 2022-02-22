# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epic::RelatedEpicLink do
  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:related_epic_link) }
    let_it_be(:issuable) { create(:epic) }
    let(:issuable_class) { 'Epic' }
    let(:issuable_link_factory) { :related_epic_link }
  end

  it_behaves_like 'issuables that can block or be blocked' do
    def factory_class
      :related_epic_link
    end

    let(:issuable_type) { :epic }

    let_it_be(:blocked_issuable_1) { create(:epic) }
    let_it_be(:blocked_issuable_2) { create(:epic) }
    let_it_be(:blocked_issuable_3) { create(:epic) }
    let_it_be(:blocking_issuable_1) { create(:epic) }
    let_it_be(:blocking_issuable_2) { create(:epic) }
  end
end
