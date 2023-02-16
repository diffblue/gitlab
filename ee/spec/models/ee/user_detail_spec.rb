# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail, feature_category: :system_access do
  it { is_expected.to belong_to(:provisioned_by_group) }

  describe '#provisioned_by_group?' do
    let(:user) { create(:user, provisioned_by_group: build(:group)) }

    subject { user.user_detail.provisioned_by_group? }

    it 'returns true when user is provisioned by group' do
      expect(subject).to eq(true)
    end

    it 'returns true when user is provisioned by group' do
      user.user_detail.update!(provisioned_by_group: nil)

      expect(subject).to eq(false)
    end
  end

  describe '#provisioned_by_group_at' do
    let(:user) { create(:user, provisioned_by_group: build(:group)) }

    subject { user.user_detail.provisioned_by_group_at }

    it 'is nil by default' do
      expect(subject).to be_nil
    end
  end

  describe 'scopes' do
    context 'for enterprise users' do
      let_it_be(:user_detail_of_enterprise_user_created_via_saml) do
        create(:user, :enterprise_user_created_via_saml).user_detail
      end

      let_it_be(:user_detail_of_enterprise_user_created_via_scim) do
        create(:user, :enterprise_user_created_via_scim).user_detail
      end

      let_it_be(:user_detail_of_enterprise_user_based_on_domain_verification) do
        create(:user, :enterprise_user_based_on_domain_verification).user_detail
      end

      let_it_be(:user_details_of_non_enterprise_users) { create_list(:user_detail, 3) }

      describe '.enterprise' do
        it 'returns user details of all enterprise users' do
          expect(described_class.enterprise).to contain_exactly(
            user_detail_of_enterprise_user_created_via_saml,
            user_detail_of_enterprise_user_created_via_scim,
            user_detail_of_enterprise_user_based_on_domain_verification
          )
        end
      end

      describe '.enterprise_created_via_saml_or_scim' do
        it 'returns user details of enterprise users created via saml or scim' do
          expect(described_class.enterprise_created_via_saml_or_scim).to contain_exactly(
            user_detail_of_enterprise_user_created_via_saml,
            user_detail_of_enterprise_user_created_via_scim
          )
        end
      end

      describe '.enterprise_based_on_domain_verification' do
        it 'returns user details of enterprise users based on domain verification' do
          expect(described_class.enterprise_based_on_domain_verification).to contain_exactly(
            user_detail_of_enterprise_user_based_on_domain_verification
          )
        end
      end
    end
  end
end
