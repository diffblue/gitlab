# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RoutableActions::SsoEnforcementRedirect, feature_category: :system_access do
  let(:saml_provider) { create(:saml_provider, enforced_sso: true) }
  let(:root_group) { saml_provider.group }
  let(:nested_group) { create(:group, :private, parent: root_group) }
  let(:project) { create(:project, :private, group: root_group) }
  let(:nested_project) { create(:project, :private, group: nested_group) }

  describe '#should_redirect_to_group_saml_sso?' do
    let(:user) { build_stubbed(:user) }
    let(:request) { double(:request, get?: true) }

    it 'returns false for User routables' do
      routable = build_stubbed(:user)

      subject = described_class.new(routable, '/')

      expect(subject.should_redirect_to_group_saml_sso?(double, double)).to eq(false)
    end

    it 'returns false when routable is nil' do
      subject = described_class.new(nil, '/')

      expect(subject.should_redirect_to_group_saml_sso?(double, double)).to eq(false)
    end

    shared_examples 'a routable with SSO enforcement redirect' do
      it 'is false when a new sso session is not needed' do
        expect_next_instance_of(BasePolicy) do |policy|
          expect(policy).to receive(:needs_new_sso_session?).and_return(false)
        end

        expect(subject.should_redirect_to_group_saml_sso?(user, request)).to eq false
      end

      it 'is true when a new sso session is needed' do
        expect_next_instance_of(BasePolicy) do |policy|
          expect(policy).to receive(:needs_new_sso_session?).and_return(true)
        end

        expect(subject.should_redirect_to_group_saml_sso?(user, request)).to eq true
      end
    end

    context 'with a project' do
      subject { described_class.new(project, '/') }

      it_behaves_like 'a routable with SSO enforcement redirect'
    end

    context 'with a nested project' do
      subject { described_class.new(nested_project, '/') }

      it_behaves_like 'a routable with SSO enforcement redirect'
    end

    context 'with a project in a personal namespace' do
      subject { described_class.new(create(:project), '/') }

      it 'returns false' do
        expect(subject.should_redirect_to_group_saml_sso?(user, double)).to eq false
      end
    end

    context 'with a group' do
      subject { described_class.new(root_group, '/') }

      it_behaves_like 'a routable with SSO enforcement redirect'
    end

    context 'with a nested group' do
      subject { described_class.new(nested_group, '/') }

      it_behaves_like 'a routable with SSO enforcement redirect'
    end
  end

  describe '#sso_redirect_url' do
    shared_examples 'a routable SSO url' do
      it 'returns the SSO url for the root group' do
        redirect_url = CGI.escape("/#{subject.routable.full_path}")

        expect(subject.sso_redirect_url).to match(%r{groups/#{root_group.to_param}/-/saml/sso\?redirect=#{redirect_url}&token=})
      end
    end

    context 'with a group' do
      subject { described_class.new(root_group, "/#{root_group.full_path}") }

      it_behaves_like 'a routable SSO url'
    end

    context 'with a nested group' do
      subject { described_class.new(nested_group, "/#{nested_group.full_path}") }

      it_behaves_like 'a routable SSO url'
    end

    context 'with a project' do
      subject { described_class.new(project, "/#{project.full_path}") }

      it_behaves_like 'a routable SSO url'
    end

    context 'with a nested project' do
      subject { described_class.new(nested_project, "/#{nested_project.full_path}") }

      it_behaves_like 'a routable SSO url'
    end
  end
end
