# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Abuse reports on epics', :js, feature_category: :insider_threat do
  let_it_be(:abusive_user) { create(:user) }
  let_it_be(:reporter1) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:epic) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true)
    sign_in(reporter1)
  end

  describe 'report abuse to administrator' do
    context 'when reporting a comment' do
      let_it_be(:note) { create(:note, author: abusive_user, noteable: epic) }

      before do
        visit group_epic_path(group, epic)
        find('.more-actions-toggle button').click
      end

      it_behaves_like 'reports the user with an abuse category'
    end
  end
end
