# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::UserWithAdmin do
  subject { entity.as_json }

  let_it_be(:user) { create(:user) }

  let(:entity) { ::API::Entities::UserWithAdmin.new(user) }

  context 'using_license_seat' do
    context 'when user is using seat' do
      it 'returns true' do
        expect(subject[:using_license_seat]).to be true
      end
    end

    context 'when user is not using seat' do
      it 'returns false' do
        allow(user).to receive(:using_license_seat?).and_return(false)

        expect(subject[:using_license_seat]).to be false
      end
    end
  end

  context 'is_auditor' do
    context 'when auditor_user is available' do
      it 'returns false when user is not an auditor' do
        expect(subject[:is_auditor]).to be false
      end

      context 'when user is an auditor' do
        let(:user) { create(:user, :auditor) }

        it 'returns true' do
          expect(subject[:is_auditor]).to be true
        end
      end
    end

    context 'when auditor_user is not available' do
      before do
        stub_licensed_features(auditor_user: false)
      end

      it 'does not have the is_auditor param' do
        expect(subject[:is_auditor]).to be nil
      end
    end
  end

  context 'provisioned_by_group_id' do
    context 'group_saml is available' do
      before do
        stub_licensed_features(group_saml: true)
      end

      it 'returns false when user is not provisioned by group' do
        expect(subject[:provisioned_by_group]).to be nil
      end

      context 'when user is provisioned by group' do
        let(:group) { create(:group) }
        let(:saml_provider) { create(:saml_provider, group: group) }
        let!(:group_saml_identity) { create(:group_saml_identity, saml_provider: saml_provider, user: user) }

        before do
          user.update!(provisioned_by_group: saml_provider.group)
        end
        it 'returns group_id' do
          expect(subject[:provisioned_by_group_id]).to eq(group.id)
        end
      end
    end

    context 'when group_saml is not available' do
      before do
        stub_licensed_features(group_saml: false)
      end

      it 'does not have the provisioned_by_group_id param' do
        expect(subject[:provisioned_by_group_id]).to be nil
      end
    end
  end

  context 'enterprise_group_id' do
    context 'when domain_verification is available' do
      before do
        stub_licensed_features(domain_verification: true)
      end

      it 'returns nil when user is not associated with an enterprise group' do
        expect(subject[:enterprise_group_id]).to be nil
      end

      context 'when user is associated with an enterprise group' do
        let(:group) { create(:group) }
        let!(:user_detail) { create(:user_detail, user: user, enterprise_group_id: group.id) }

        it 'returns the id of the enterprise group' do
          expect(subject[:enterprise_group_id]).to eq(group.id)
        end
      end
    end

    context 'when domain_verification is not available' do
      before do
        stub_licensed_features(domain_verification: false)
      end

      it 'does not have the enterprise_group_id param' do
        expect(subject[:enterprise_group_id]).to be nil
      end
    end
  end

  context 'enterprise_group_associated_at' do
    context 'when domain_verification is available' do
      before do
        stub_licensed_features(domain_verification: true)
      end

      it 'returns nil when user is not associated with an enterprise group' do
        expect(subject[:enterprise_group_associated_at]).to be nil
      end

      context 'when user is associated with an enterprise group' do
        let(:group) { create(:group) }
        let(:associated_at) { Time.current }
        let!(:user_detail) do
          create(:user_detail, user: user, enterprise_group_id: group.id, enterprise_group_associated_at: associated_at)
        end

        it 'returns the time when the user was associated with the enterprise group' do
          expect(subject[:enterprise_group_associated_at]).to eq(associated_at)
        end
      end
    end

    context 'when domain_verification is not available' do
      before do
        stub_licensed_features(domain_verification: false)
      end

      it 'does not have the enterprise_group_associated_at param' do
        expect(subject[:enterprise_group_associated_at]).to be nil
      end
    end
  end
end
