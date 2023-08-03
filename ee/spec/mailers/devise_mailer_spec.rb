# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe DeviseMailer do
  describe "#confirmation_instructions", feature_category: :user_management do
    let_it_be(:unsaved_user) { create(:user, name: 'Jane Doe', email: 'jdoe@example.com') }

    subject(:mail) { described_class.confirmation_instructions(unsaved_user, 'faketoken', {}) }

    context 'when additional custom text is added' do
      let(:custom_text) { 'this is some additional custom text' }

      before do
        stub_licensed_features(email_additional_text: true)
        stub_ee_application_setting(email_additional_text: custom_text)
      end

      it "includes the additional custom text" do
        expect(mail).to have_text custom_text
      end
    end

    it_behaves_like 'an email with information about unconfirmed user settings'
  end
end
