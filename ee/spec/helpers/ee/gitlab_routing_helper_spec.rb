# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::GitlabRoutingHelper do
  include ProjectsHelper
  include ApplicationSettingsHelper

  let_it_be(:primary, reload: true) do
    create(
      :geo_node,
      :primary,
      url: 'http://localhost:123/relative',
      internal_url: 'http://internal:321/relative',
      clone_url_prefix: 'git@localhost:'
    )
  end

  let_it_be(:group, reload: true) { create(:group, path: 'foo') }
  let_it_be(:project, reload: true) { create(:project, namespace: group, path: 'bar') }

  describe '#geo_primary_web_url' do
    before do
      allow(helper).to receive(:default_clone_protocol).and_return('http')
    end

    context 'public / default URL' do
      it 'generates a path to the project' do
        result = helper.geo_primary_web_url(project)

        expect(result).to eq('http://localhost:123/relative/foo/bar')
      end

      it 'generates a path to the wiki' do
        result = helper.geo_primary_web_url(project.wiki)

        expect(result).to eq('http://localhost:123/relative/foo/bar.wiki')
      end
    end

    context 'internal URL' do
      it 'generates a path to the project' do
        result = helper.geo_primary_web_url(project, internal: true)

        expect(result).to eq('http://internal:321/relative/foo/bar')
      end

      it 'generates a path to the wiki' do
        result = helper.geo_primary_web_url(project.wiki, internal: true)

        expect(result).to eq('http://internal:321/relative/foo/bar.wiki')
      end
    end
  end

  describe '#geo_primary_default_url_to_repo' do
    subject { helper.geo_primary_default_url_to_repo(repo) }

    context 'HTTP' do
      before do
        allow(helper).to receive(:default_clone_protocol).and_return('http')
      end

      context 'project' do
        let(:repo) { project }

        it { is_expected.to eq('http://localhost:123/relative/foo/bar.git') }
      end

      context 'wiki' do
        let(:repo) { project.wiki }

        it { is_expected.to eq('http://localhost:123/relative/foo/bar.wiki.git') }
      end
    end

    context 'HTTPS' do
      before do
        allow(helper).to receive(:default_clone_protocol).and_return('https')
        primary.update!(url: 'https://localhost:123/relative')
      end

      context 'project' do
        let(:repo) { project }

        it { is_expected.to eq('https://localhost:123/relative/foo/bar.git') }
      end

      context 'wiki' do
        let(:repo) { project.wiki }

        it { is_expected.to eq('https://localhost:123/relative/foo/bar.wiki.git') }
      end
    end

    context 'SSH' do
      before do
        allow(helper).to receive(:default_clone_protocol).and_return('ssh')
      end

      context 'project' do
        let(:repo) { project }

        it { is_expected.to eq('git@localhost:foo/bar.git') }
      end

      context 'wiki' do
        let(:repo) { project.wiki }

        it { is_expected.to eq('git@localhost:foo/bar.wiki.git') }
      end
    end
  end

  describe '#license_management_settings_path' do
    it 'generates a path to the license compliance page' do
      result = helper.license_management_settings_path(project)

      expect(result).to eq('/foo/bar/-/licenses#policies')
    end
  end

  describe '#user_group_saml_omniauth_metadata_path' do
    subject do
      helper.user_group_saml_omniauth_metadata_path(group)
    end

    before do
      group.update!(saml_discovery_token: 'sometoken')
    end

    it 'uses metadata path' do
      expect(subject).to start_with('/users/auth/group_saml/metadata')
    end

    it 'appends group path and token' do
      expect(subject).to end_with('?group_path=foo&token=sometoken')
    end
  end

  describe '#user_group_saml_omniauth_metadata_url' do
    subject do
      helper.user_group_saml_omniauth_metadata_url(group)
    end

    it 'creates full metadata URL' do
      expect(subject).to start_with 'http://localhost/users/auth/group_saml/metadata?group_path=foo&token='
    end
  end

  describe '#upgrade_plan_path' do
    subject { upgrade_plan_path(group) }

    context 'when the group is present' do
      let(:group) { build_stubbed(:group) }

      it "returns the group billing path" do
        expect(subject).to eq(group_billings_path(group))
      end
    end

    context 'when the group is blank' do
      let(:group) { nil }

      it "returns the profile billing path" do
        expect(subject).to eq(profile_billings_path)
      end
    end
  end

  describe '#vulnerability_url' do
    let_it_be(:vulnerability) { create(:vulnerability) }

    subject { vulnerability_url(vulnerability) }

    it 'returns the full url of the vulnerability' do
      expect(subject).to eq "http://localhost/#{vulnerability.project.namespace.path}/#{vulnerability.project.name}/-/security/vulnerabilities/#{vulnerability.id}"
    end
  end

  describe '#usage_quotas_path' do
    it 'returns the group usage quota path for a group namespace' do
      group = build(:group)

      expect(usage_quotas_path(group)).to eq("/groups/#{group.full_path}/-/usage_quotas")
    end

    it 'returns the profile usage quotas path for any other namespace' do
      namespace = build(:namespace)

      expect(usage_quotas_path(namespace)).to eq('/-/profile/usage_quotas')
    end

    it 'returns the path with any args supplied' do
      namespace = build(:namespace)

      expect(usage_quotas_path(namespace, foo: 'bar', anchor: 'quotas-tab')).to eq('/-/profile/usage_quotas?foo=bar#quotas-tab')
    end
  end

  describe '#usage_quotas_url' do
    it 'returns the group usage quota url for a group namespace' do
      group = build(:group)

      expect(usage_quotas_url(group)).to eq("http://test.host/groups/#{group.full_path}/-/usage_quotas")
    end

    it 'returns the profile usage quotas url for any other namespace' do
      namespace = build(:namespace)

      expect(usage_quotas_url(namespace)).to eq('http://test.host/-/profile/usage_quotas')
    end

    it 'returns the url with any args supplied' do
      namespace = build(:namespace)

      expect(usage_quotas_url(namespace, foo: 'bar', anchor: 'quotas-tab')).to eq('http://test.host/-/profile/usage_quotas?foo=bar#quotas-tab')
    end
  end
end
