# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Noteable::NotesChannel, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:developer) { create(:user).tap { |u| group.add_developer(u) } }

  describe '#subscribed' do
    let(:subscribe_params) do
      {
        group_id: noteable.group_id,
        noteable_type: noteable.class.underscore,
        noteable_id: noteable.id
      }
    end

    before do
      stub_action_cable_connection current_user: developer
    end

    context 'on an epic' do
      let_it_be(:noteable) { create(:epic, group: group) }

      before do
        stub_licensed_features(epics: true)
      end

      it_behaves_like 'handle subscription based on user access'
    end
  end
end
