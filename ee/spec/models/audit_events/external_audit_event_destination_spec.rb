# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ExternalAuditEventDestination do
  subject { create(:external_audit_event_destination) }

  let_it_be(:group) { create(:group) }

  describe 'Associations' do
    it 'belongs to a group' do
      expect(subject.group).not_to be_nil
    end
  end

  describe 'Validations' do
    it { is_expected.to validate_length_of(:destination_url).is_at_most(255) }
    it { is_expected.to validate_presence_of(:destination_url) }
    it { is_expected.to have_db_column(:verification_token).of_type(:text) }

    it 'must have a unique destination_url' do
      create(:external_audit_event_destination, destination_url: 'https://example.com/1', group: group)
      dup = build(:external_audit_event_destination, destination_url: 'https://example.com/1', group: group)
      dup.save # rubocop:disable Rails/SaveBang

      expect(dup.errors.full_messages).to include('Destination url has already been taken')
    end

    it 'must not have any parents' do
      destination = build(:external_audit_event_destination, group: create(:group, :nested))
      destination.save # rubocop:disable Rails/SaveBang

      expect(destination.errors.full_messages).to include('Group must not be a subgroup')
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:external_audit_event_destination, group: create(:group)) }
  end
end
