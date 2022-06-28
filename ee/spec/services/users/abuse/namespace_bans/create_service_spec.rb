# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::NamespaceBans::CreateService do
  let(:user) { build(:user) }
  let(:namespace) { build(:group) }
  let(:service) { described_class.new(user: user, namespace: namespace) }

  subject(:execute) { service.execute }

  describe 'when passing a root namespace' do
    it { is_expected.to match(status: :success) }
  end

  describe 'when passing a nested namespace' do
    let(:namespace) { build(:group, :nested) }

    it { is_expected.to match(status: :error, message: 'Namespace must be a root namespace') }
  end

  describe 'when passing an already banned user' do
    before do
      service.execute
    end

    it { is_expected.to match(status: :error, message: 'User already banned from namespace') }
  end
end
