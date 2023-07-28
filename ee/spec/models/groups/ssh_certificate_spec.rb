# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SshCertificate, feature_category: :source_code_management do
  describe 'associations' do
    it 'belongs to a group' do
      is_expected.to belong_to(:group).with_foreign_key(:namespace_id).inverse_of(:ssh_certificates)
    end
  end

  subject { build(:group_ssh_certificate) }

  describe 'validations' do
    it 'presence fields' do
      is_expected.to validate_presence_of(:group)
      is_expected.to validate_presence_of(:key)
      is_expected.to validate_presence_of(:title)
      is_expected.to validate_presence_of(:fingerprint)
    end

    it 'length of key and title' do
      is_expected.to validate_length_of(:title).is_at_most(255)
      is_expected.to validate_length_of(:key).is_at_most(512.kilobytes)
    end

    it 'uniqueness of fingerprint' do
      is_expected.to validate_uniqueness_of(:fingerprint).with_message(
        'must be unique. This CA has already been configured for another namespace.'
      )
    end
  end
end
