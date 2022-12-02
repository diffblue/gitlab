# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Suggested Reviewers secret initialization for GitLab EE', feature_category: :workflow_automation do
  subject { Gitlab::Application.config }

  let(:load_suggested_reviewers_secret) do
    load Rails.root.join('config/initializers/gitlab_suggested_reviewers_secret.rb')
  end

  context 'when not SAAS' do
    it 'does not load secret' do
      expect(Gitlab::AppliedMl::SuggestedReviewers).not_to receive(:ensure_secret!)

      load_suggested_reviewers_secret
    end
  end

  context 'when SAAS', :saas do
    it 'loads secret' do
      expect(Gitlab::AppliedMl::SuggestedReviewers).to receive(:ensure_secret!)

      load_suggested_reviewers_secret
    end
  end
end
