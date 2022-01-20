# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ExternalAuditEventDestination do
  subject { build(:external_audit_event_destination) }

  describe 'Associations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'Validations' do
    it { is_expected.to validate_uniqueness_of(:destination_url).scoped_to(:namespace_id) }
    it { is_expected.to validate_length_of(:destination_url).is_at_most(255) }
    it { is_expected.to validate_presence_of(:destination_url) }
    it { is_expected.to have_db_column(:verification_token).of_type(:text) }
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:external_audit_event_destination, group: create(:group)) }
  end
end
