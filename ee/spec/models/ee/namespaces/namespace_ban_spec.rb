# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::NamespaceBan do
  let(:namespace_ban) { build(:namespace_ban, namespace: namespace) }
  let(:namespace) { build(:group, parent: nil) }

  subject { namespace_ban }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to belong_to(:user).required }
    it do
      is_expected.to(
        validate_uniqueness_of(:user_id)
          .scoped_to(:namespace_id)
          .with_message('already banned from namespace'))
    end
  end

  describe 'validations' do
    describe 'namespace_is_root_namespace' do
      context 'when associated namespace is root' do
        it { is_expected.to be_valid }
      end

      context 'when associated namespace is not root' do
        let(:namespace) { build(:group, :nested) }

        it 'is invalid' do
          expect(subject).to be_invalid
          expect(subject.errors[:namespace]).to include('must be a root namespace')
        end
      end
    end
  end
end
