# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CredentialsInventoryMailer do
  include EmailSpec::Matchers

  let_it_be(:administrator) { create(:user, :admin, username: 'Revoker') }

  describe '#personal_access_token_revoked_email' do
    let_it_be(:token) { create(:personal_access_token, scopes: %w(api sudo), last_used_at: 3.weeks.ago) }

    subject(:email) { described_class.personal_access_token_revoked_email(token: token, revoked_by: administrator) }

    it { is_expected.to have_subject 'Your Personal Access Token was revoked' }
    it { is_expected.to have_body_text 'The following Personal Access Token was revoked by an administrator, Revoker' }
    it { is_expected.to have_body_text token.name }
    it { is_expected.to have_body_text "Created on #{token.created_at.to_date.to_s(:medium)}" }
    it { is_expected.to have_body_text 'Scopes: api, sudo'}
    it { is_expected.to be_delivered_to [token.user.notification_email] }
    it { is_expected.to have_body_text 'Last used 21 days ago' }
  end

  describe '#ssh_key_deleted_email' do
    let_it_be(:ssh_key) { create(:personal_key, last_used_at: 3.weeks.ago) }

    let(:params) do
      {
          notification_email: ssh_key.user.notification_email,
          title: ssh_key.title,
          last_used_at: ssh_key.last_used_at,
          created_at: ssh_key.created_at
      }
    end

    subject(:email) { described_class.ssh_key_deleted_email(params: params, deleted_by: administrator) }

    it { is_expected.to have_subject 'Your SSH key was deleted' }
    it { is_expected.to have_body_text 'The following SSH key was deleted by an administrator, Revoker' }
    it { is_expected.to be_delivered_to [ssh_key.user.notification_email] }
    it { is_expected.to have_body_text ssh_key.title }
    it { is_expected.to have_body_text "Created on #{ssh_key.created_at.to_date.to_s(:medium)}" }
    it { is_expected.to have_body_text 'Last used 21 days ago' }
  end
end
