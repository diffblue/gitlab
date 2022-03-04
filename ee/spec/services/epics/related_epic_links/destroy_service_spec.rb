# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::DestroyService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let!(:issuable_link) { create(:related_epic_link) }

    before do
      stub_licensed_features(epics: true, related_epics: true)
    end

    subject { described_class.new(issuable_link, user).execute }

    it_behaves_like 'a destroyable issuable link'
  end
end
