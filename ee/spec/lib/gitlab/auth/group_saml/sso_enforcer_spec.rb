# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::SsoEnforcer, feature_category: :authentication_and_authorization do
  let(:saml_provider) { build_stubbed(:saml_provider, enforced_sso: true) }
  let(:session) { {} }

  before do
    stub_licensed_features(group_saml: true)
  end

  around do |example|
    Gitlab::Session.with_session(session) do
      example.run
    end
  end

  subject { described_class.new(saml_provider) }

  describe '#update_session' do
    it 'stores that a session is active for the given provider' do
      expect { subject.update_session }.to change { session[:active_group_sso_sign_ins] }
    end

    it 'stores the current time for later comparison' do
      freeze_time do
        subject.update_session

        expect(session[:active_group_sso_sign_ins][saml_provider.id]).to eq DateTime.now
      end
    end
  end

  describe '#active_session?' do
    it 'returns false if nothing has been stored' do
      expect(subject).not_to be_active_session
    end

    it 'returns true if a sign in has been recorded' do
      subject.update_session

      expect(subject).to be_active_session
    end

    describe 'enforced sso expiry' do
      before do
        stub_feature_flags(enforced_sso_expiry: saml_provider.group)
      end

      it 'returns true if a sign in is recently recorded' do
        subject.update_session

        expect(subject).to be_active_session
      end

      it 'returns false if the sign in predates the session timeout' do
        subject.update_session

        days_after_timeout = Gitlab::Auth::GroupSaml::SsoEnforcer::DEFAULT_SESSION_TIMEOUT + 2.days
        travel_to(days_after_timeout.from_now) do
          expect(subject).not_to be_active_session
        end
      end
    end
  end

  describe '#allows_access?' do
    it 'allows access when saml_provider is nil' do
      subject = described_class.new(nil)

      expect(subject).not_to be_access_restricted
    end

    context 'when sso enforcement is disabled' do
      let(:saml_provider) { build_stubbed(:saml_provider, enforced_sso: false) }

      it 'allows access when sso enforcement is disabled' do
        expect(subject).not_to be_access_restricted
      end
    end

    context 'when saml_provider is disabled' do
      let(:saml_provider) { build_stubbed(:saml_provider, enforced_sso: true, enabled: false) }

      it 'allows access when saml_provider is disabled' do
        expect(subject).not_to be_access_restricted
      end
    end

    it 'prevents access when sso enforcement active but there is no session' do
      expect(subject).to be_access_restricted
    end

    it 'allows access when sso is enforced but a saml session is active' do
      subject.update_session

      expect(subject).not_to be_access_restricted
    end
  end

  describe '.group_access_restricted?' do
    context 'when SSO is enforced' do
      let(:root_group) { create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true)) }

      context 'is restricted' do
        it 'for a group' do
          expect(described_class).to be_group_access_restricted(root_group)
        end

        it 'for a subgroup' do
          sub_group = create(:group, parent: root_group)

          expect(described_class).to be_group_access_restricted(sub_group)
        end
      end

      context 'for group owner' do
        let(:user) { create(:user) }

        before do
          create(:group_saml_identity, user: user, saml_provider: root_group.saml_provider)
          root_group.add_owner(user)
        end

        context 'for a root group' do
          it 'is not restricted' do
            expect(described_class).not_to be_group_access_restricted(root_group, user: user)
          end
        end

        context 'for a subgroup' do
          it 'is restricted' do
            sub_group = create(:group, parent: root_group)

            expect(described_class).to be_group_access_restricted(sub_group, user: user)
          end
        end

        context 'for a project' do
          it 'restricts access' do
            create(:project, group: root_group)

            expect(described_class).to be_group_access_restricted(root_group, user: user, for_project: true)
          end
        end
      end

      context 'when user is a deploy token' do
        it 'allows access' do
          deploy_token = create(:deploy_token)

          # Deploy Tokens are considered sessionless
          Gitlab::Session.with_session(nil) do
            expect(described_class).not_to be_group_access_restricted(root_group, user: deploy_token)
          end
        end
      end
    end

    context 'when SSO is enabled but not enforced' do
      let(:root_group) { create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: false)) }
      let(:user) { create(:user) }

      before do
        stub_feature_flags(transparent_sso_enforcement_override: false)
      end

      shared_examples 'restricted access for all groups in the hierarchy' do
        it 'restricts access for a group' do
          expect(described_class).to be_group_access_restricted(root_group, user: user)
        end

        it 'restricts access for a subgroup' do
          sub_group = create(:group, parent: root_group)

          expect(described_class).to be_group_access_restricted(sub_group, user: user)
        end

        it 'restricts access for a project' do
          create(:project, group: root_group)

          expect(described_class).to be_group_access_restricted(root_group, user: user, for_project: true)
        end
      end

      shared_examples 'unrestricted access for all groups in the hierarchy' do
        it 'access is not restricted for a group' do
          expect(described_class).not_to be_group_access_restricted(root_group, user: user)
        end

        it 'access is not restricted for a subgroup' do
          sub_group = create(:group, parent: root_group)

          expect(described_class).not_to be_group_access_restricted(sub_group, user: user)
        end
      end

      context 'when the user has a SAML identity' do
        before do
          create(:group_saml_identity, user: user, saml_provider: root_group.saml_provider)
        end

        it_behaves_like 'restricted access for all groups in the hierarchy'

        context 'when the SAML provider is not enabled' do
          before do
            root_group.saml_provider.update!(enabled: false)
          end

          it_behaves_like 'unrestricted access for all groups in the hierarchy'
        end

        context 'when Group SAML is not licensed' do
          before do
            stub_licensed_features(group_saml: false)
          end

          it_behaves_like 'unrestricted access for all groups in the hierarchy'
        end

        context 'when the transparent_sso_enforcement feature flag is disabled globally' do
          before do
            stub_feature_flags(transparent_sso_enforcement: false)
          end

          it_behaves_like 'unrestricted access for all groups in the hierarchy'

          context 'when the transparent_sso_enforcement feature flag is enabled for a top-level group' do
            before do
              stub_feature_flags(transparent_sso_enforcement: root_group)
            end

            it_behaves_like 'restricted access for all groups in the hierarchy'

            context 'when the transparent_sso_enforcement_override feature flag is enabled for the same group' do
              before do
                stub_feature_flags(transparent_sso_enforcement_override: root_group)
              end

              it_behaves_like 'unrestricted access for all groups in the hierarchy'
            end
          end
        end
      end

      context 'when the user does not have a SAML identity' do
        it 'access is not restricted' do
          expect(described_class).not_to be_group_access_restricted(root_group, user: user)
        end
      end
    end

    context 'for a group without a saml_provider configured' do
      let(:root_group) { create(:group) }

      it 'is not restricted' do
        expect(described_class).not_to be_group_access_restricted(root_group)
      end
    end
  end
end
