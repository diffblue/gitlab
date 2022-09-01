# frozen_string_literal: true

RSpec.shared_examples 'hides email confirmation warning' do
  RSpec::Matchers.define :set_confirm_warning_for do |email|
    match do |_response|
      msg = "Please check your email (#{email}) to verify that you own this address and unlock the power of CI/CD."

      expect(controller).to set_flash.now[:warning].to include(msg)
    end
  end

  context 'with an unconfirmed email address present' do
    let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'unconfirmed@gitlab.com') }

    it { is_expected.not_to set_confirm_warning_for(user.unconfirmed_email) }
  end

  context 'without an unconfirmed email address present' do
    let(:user) { create(:user, confirmed_at: nil) }

    it { is_expected.not_to set_confirm_warning_for(user.email) }
  end
end
