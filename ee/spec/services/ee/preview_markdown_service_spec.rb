# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreviewMarkdownService, feature_category: :team_planning do
  context 'preview epic text with quick action' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:epic) { create(:epic, group: group) }
    let(:params) do
      {
        text: '/title new title',
        target_type: 'Epic',
        target_id: epic.iid,
        group: epic.group
      }
    end

    let(:service) { described_class.new(nil, user, params) }

    before do
      stub_licensed_features(epics: true)
      group.add_developer(user)
    end

    it 'explains quick actions effect' do
      result = service.execute

      expect(result[:commands]).to eq 'Changes the title to "new title".'
    end
  end
end
