# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::SsoEnforcer, feature_category: :system_access do
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

    it 'returns false if the sign in predates the session timeout' do
      subject.update_session

      days_after_timeout = Gitlab::Auth::GroupSaml::SsoEnforcer::DEFAULT_SESSION_TIMEOUT + 2.days
      travel_to(days_after_timeout.from_now) do
        expect(subject).not_to be_active_session
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
    context 'when SAML SSO is enabled for resource' do
      using RSpec::Parameterized::TableSyntax

      let(:saml_provider) { create(:saml_provider, enabled: true, enforced_sso: false) }
      let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
      let(:root_group) { saml_provider.group }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:project) { create(:project, group: root_group) }
      let(:member_with_identity) { identity.user }
      let(:member_without_identity) { create(:user) }
      let(:non_member) { create(:user) }
      let(:not_signed_in_user) { nil }
      let(:deploy_token) { create(:deploy_token) }

      before do
        stub_licensed_features(group_saml: true)
        root_group.add_developer(member_with_identity)
        root_group.add_developer(member_without_identity)
      end

      shared_examples 'SSO Enforced' do
        it 'returns true' do
          expect(described_class.group_access_restricted?(resource, user: user)).to eq(true) if resource.is_a?(Group)

          if resource.is_a?(Project)
            expect(described_class.group_access_restricted?(resource.group, user: user, for_project: true)).to eq(true)
          end
        end
      end

      shared_examples 'SSO Not enforced' do
        it 'returns false' do
          expect(described_class.group_access_restricted?(resource, user: user)).to eq(false) if resource.is_a?(Group)

          if resource.is_a?(Project)
            expect(described_class.group_access_restricted?(resource.group, user: user, for_project: true)).to eq(false)
          end
        end
      end

      # See https://docs.gitlab.com/ee/user/group/saml_sso/#sso-enforcement
      where(:resource, :resource_visibility_level, :enforced_sso?, :user, :user_is_resource_owner?, :user_with_saml_session?, :user_is_admin?, :enable_admin_mode?, :user_is_auditor?, :shared_examples) do
        # Project/Group visibility: Private; Enforce SSO setting: Off

        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        # Project/Group visibility: Private; Enforce SSO setting: On

        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:root_group) | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'private' | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'private' | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'private' | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        # Project/Group visibility: Public; Enforce SSO setting: Off

        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        ref(:root_group) | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | false | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'

        # Project/Group visibility: Public; Enforce SSO setting: On

        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'SSO Not enforced'

        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'SSO Not enforced'

        # As per the table, SSO is not enforced for the cases below.
        # That is handled on Group/Project policy level, see
        # - ee/spec/controllers/concerns/routable_actions_spec.rb
        # - ee/spec/policies/group_policy_spec.rb
        # - ee/spec/policies/project_policy_spec.rb
        # files.
        #
        # `::Gitlab::Auth::GroupSaml::SsoEnforcer.group_access_restricted?` method
        # should return `true` for those cases, except for deploy_token, until that logic moves to the class.
        ref(:root_group) | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:root_group) | 'public'  | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:subgroup)   | 'public'  | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
        ref(:project)    | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'SSO Enforced'
        ref(:project)    | 'public'  | true  | ref(:deploy_token)            | nil   | nil   | nil  | nil   | nil  | 'SSO Not enforced'
      end

      with_them do
        context "when 'Enforce SSO-only authentication for web activity for this group' option is #{params[:enforced_sso?] ? 'enabled' : 'not enabled'}" do
          around do |example|
            session = {}

            # Deploy Tokens are considered sessionless
            session = nil if user.is_a?(DeployToken)

            Gitlab::Session.with_session(session) do
              example.run
            end
          end

          before do
            saml_provider.update!(enforced_sso: enforced_sso?)
          end

          context "when resource is #{params[:resource_visibility_level]}" do
            before do
              resource.update!(visibility_level: Gitlab::VisibilityLevel.string_options[resource_visibility_level])
            end

            context 'for user', enable_admin_mode: params[:enable_admin_mode?] do
              before do
                if user_is_resource_owner?
                  resource.root_ancestor.member(user).update_column(:access_level, Gitlab::Access::OWNER)
                end

                Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session if user_with_saml_session?

                user.update!(admin: true) if user_is_admin?
                user.update!(auditor: true) if user_is_auditor?
              end

              include_examples params[:shared_examples]
            end
          end
        end
      end
    end
  end

  describe '.access_restricted_groups' do
    let!(:restricted_group) { create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true)) }
    let!(:restricted_subgroup) { create(:group, parent: restricted_group) }
    let!(:restricted_group2) do
      create(:group, saml_provider: create(:saml_provider, enabled: true, enforced_sso: true))
    end

    let!(:unrestricted_group) { create(:group) }
    let!(:unrestricted_subgroup) { create(:group, parent: unrestricted_group) }
    let!(:groups) { [restricted_subgroup, restricted_group2, unrestricted_group, unrestricted_subgroup] }

    it 'handles empty groups array' do
      expect(described_class.access_restricted_groups([])).to eq([])
    end

    it 'returns a list of SSO enforced root groups' do
      expect(described_class.access_restricted_groups(groups))
        .to match_array([restricted_group, restricted_group2])
    end

    it 'returns only unique root groups' do
      expect(described_class.access_restricted_groups(groups.push(restricted_group)))
        .to match_array([restricted_group, restricted_group2])
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        described_class.access_restricted_groups([restricted_group])
      end

      expect { described_class.access_restricted_groups(groups) }.not_to exceed_all_query_limit(control)
    end
  end
end
