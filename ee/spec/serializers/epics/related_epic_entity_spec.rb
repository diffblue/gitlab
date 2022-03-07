# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicEntity do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:source) { create(:epic, group: group) }
  let_it_be(:target) { create(:epic, group: group) }
  let_it_be(:epic_link) { create(:related_epic_link, source: source, target: target) }

  let(:request) { EntityRequest.new(issuable: epic_link.source, current_user: user) }
  let(:related_epic) { epic_link.source.related_epics(user).first }
  let(:entity) { described_class.new(related_epic, { request: request, current_user: user }) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
    group.add_developer(user)
  end

  describe '#as_json' do
    it 'matches json schema' do
      expect(entity.to_json).to match_schema('entities/related_epic', dir: 'ee')
    end
  end
end
