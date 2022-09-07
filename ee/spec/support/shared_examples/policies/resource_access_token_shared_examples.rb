# frozen_string_literal: true

RSpec.shared_examples 'GitLab.com Paid plan resource access tokens' do
  context 'on SaaS', :saas do
    it { is_expected.to be_allowed(:create_resource_access_tokens) }
    it { is_expected.to be_allowed(:read_resource_access_tokens) }
    it { is_expected.to be_allowed(:destroy_resource_access_tokens) }

    context 'when personal access tokens are disabled' do
      before do
        stub_ee_application_setting(personal_access_tokens_disabled?: true)
      end

      it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
      it { is_expected.not_to be_allowed(:read_resource_access_tokens) }
      it { is_expected.not_to be_allowed(:destroy_resource_access_tokens) }
    end
  end
end
