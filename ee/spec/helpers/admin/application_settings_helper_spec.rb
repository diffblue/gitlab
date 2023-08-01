# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::ApplicationSettingsHelper, feature_category: :code_suggestions do
  describe 'Code Suggestions for Self-Managed instances' do
    describe '#code_suggestions_description' do
      subject { helper.code_suggestions_description }

      it { is_expected.to include 'https://docs.gitlab.com/ee/user/project/repository/code_suggestions.html' }
    end

    describe '#code_suggestions_token_explanation' do
      subject { helper.code_suggestions_token_explanation }

      it { is_expected.to include 'https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token' }
    end

    describe '#code_suggestions_agreement' do
      subject { helper.code_suggestions_agreement }

      it { is_expected.to include 'https://about.gitlab.com/handbook/legal/testing-agreement/' }
    end
  end
end
