# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Framework do
  describe 'validations' do
    let_it_be(:framework) { create(:compliance_framework) }

    subject { framework }

    it { is_expected.to validate_uniqueness_of(:namespace_id).scoped_to(:name) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(255) }
    it { is_expected.to validate_length_of(:color).is_at_most(10) }
    it { is_expected.to validate_length_of(:pipeline_configuration_full_path).is_at_most(255) }

    describe 'namespace_is_root_level_group' do
      context 'when namespace is a root group' do
        let_it_be(:namespace) { create(:group) }
        let_it_be(:framework) { build(:compliance_framework, namespace: namespace) }

        it 'is valid' do
          expect(framework).to be_valid
        end
      end

      context 'when namespace is a user namespace' do
        let_it_be(:namespace) { create(:user_namespace) }
        let_it_be(:framework) { build(:compliance_framework, namespace: namespace) }

        it 'is invalid' do
          expect(framework).not_to be_valid
          expect(framework.errors[:namespace]).to include('must be a group, user namespaces are not supported.')
        end
      end

      context 'when namespace is a subgroup' do
        let_it_be(:namespace) { create(:group, :nested) }
        let_it_be(:framework) { build(:compliance_framework, namespace: namespace) }

        it 'is invalid' do
          expect(framework).not_to be_valid
          expect(framework.errors[:namespace]).to include('must be a root group.')
        end
      end
    end
  end

  describe 'color' do
    context 'with whitespace' do
      subject { create(:compliance_framework, color: ' #ABC123 ') }

      it 'strips whitespace' do
        expect(subject.color).to eq('#ABC123')
      end
    end
  end
end
