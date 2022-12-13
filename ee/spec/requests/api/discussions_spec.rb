# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Discussions, feature_category: :team_planning do
  let(:user)         { create(:user) }
  let!(:project)     { create(:project, :public, :repository, namespace: user.namespace) }
  let(:private_user) { create(:user) }

  before do
    project.add_developer(user)
  end

  context 'when noteable is an Epic' do
    let(:group)      { create(:group, :public) }
    let(:epic)       { create(:epic, group: group, author: user) }
    let!(:epic_note) { create(:discussion_note, noteable: epic, project: project, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'discussions API', 'groups', 'epics', 'id', can_reply_to_individual_notes: true do
      let(:parent)   { group }
      let(:noteable) { epic }
      let(:note)     { epic_note }
    end
  end
end
