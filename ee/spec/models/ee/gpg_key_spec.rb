# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKey do
  let_it_be(:gpg_key) { create(:gpg_key) }
  let_it_be(:gpg_key_2) { create(:another_gpg_key) }
  let_it_be(:user) { gpg_key.user }

  describe '.for_user' do
    subject { described_class.for_user(user) }

    it { is_expected.to contain_exactly(gpg_key) }
  end

  describe '#audit_details' do
    it "equals to the user's name" do
      expect(gpg_key.audit_details).to eq(user.name)
    end
  end
end
