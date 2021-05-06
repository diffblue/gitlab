# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard > Topics' do
  describe 'as anonymous user' do
    before do
      visit dashboard_topics_path
    end

    it 'is redirected to sign-in page' do
      expect(current_path).to eq new_user_session_path
    end
  end

  describe 'as logged-in user' do
    let(:user) { create(:user) }
    let(:user_project) { create(:project, namespace: user.namespace) }
    let(:other_project) { create(:project, :public) }

    before do
      sign_in(user)
    end

    context 'when topics exist' do
      before do
        user_project.update!(topic_list: 'topic1')
        other_project.update!(topic_list: 'topic2')
      end

      it 'renders correct topics' do
        visit dashboard_topics_path

        expect(current_path).to eq dashboard_topics_path
        expect(page).to have_content('topic1')
        expect(page).not_to have_content('topic2')
      end
    end

    context 'when no topics exist' do
      it 'renders empty message' do
        visit dashboard_topics_path

        expect(current_path).to eq dashboard_topics_path
        expect(page).to have_content('There are no topics to show')
      end
    end
  end
end
