# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsFinder, feature_category: :groups_and_projects do
  include AdminModeHelper

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group_with_wiki) { create(:group, :wiki_repo) }
    let_it_be(:group_without_wiki) { create(:group) }

    subject { described_class.new(user, params).execute }

    before_all do
      group_with_wiki.add_developer(user)
      group_without_wiki.add_developer(user)
    end

    context 'when repository storage name is given' do
      let(:params) { { repository_storage: group_with_wiki.repository_storage } }

      it 'filters by the repository storage name' do
        expect(subject).to eq([group_with_wiki])
      end
    end

    context 'when repository storage name is not given' do
      let(:params) { {} }

      it 'returns all groups' do
        expect(subject).to match_array([group_with_wiki, group_without_wiki])
      end
    end
  end
end
