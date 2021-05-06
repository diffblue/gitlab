# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Explore Topics' do
  let(:user) { create(:user) }
  let(:project_private_user) { create(:project, :private, namespace: user.namespace) }
  let(:project_private) { create(:project, :private) }
  let(:project_internal) { create(:project, :internal) }
  let(:project_public) { create(:project, :public) }

  context 'when no topics exist' do
    it 'renders empty message' do
      visit explore_topics_path

      expect(current_path).to eq explore_topics_path
      expect(page).to have_content('There are no topics to show')
    end
  end

  context 'when topics exist' do
    before do
      project_private_user.update!(topic_list: 'topic1')
      project_private.update!(topic_list: 'topic2')
      project_internal.update!(topic_list: 'topic3')
      project_public.update!(topic_list: 'topic4')
    end

    context 'as logged-in user' do
      before do
        sign_in(user)
      end

      it 'renders correct topics' do
        visit explore_topics_path

        expect(current_path).to eq explore_topics_path
        expect(page).to have_content('topic1')
        expect(page).not_to have_content('topic2')
        expect(page).to have_content('topic3')
        expect(page).to have_content('topic4')
      end
    end

    context 'as anonymous user' do
      it 'renders correct topics' do
        visit explore_topics_path

        expect(current_path).to eq explore_topics_path
        expect(page).not_to have_content('topic1')
        expect(page).not_to have_content('topic2')
        expect(page).not_to have_content('topic3')
        expect(page).to have_content('topic4')
      end
    end
  end
end
