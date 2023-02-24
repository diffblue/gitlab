# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::Geo::SshPortCheck, feature_category: :geo_replication do
  include EE::GeoHelpers

  subject { described_class.new }

  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  let(:primary_ssh_port) { 1234 }
  let(:primary_clone_url_prefix) { "ssh://git@127.0.0.1:#{primary_ssh_port}" }

  before do
    stub_current_geo_node(secondary_node)

    # Primary gets its `clone_url_prefix` set to gitlab_shell.ssh_path_prefix in the before_validation callback
    # Use custom clone_url_prefix
    primary_node.update_column(:clone_url_prefix, primary_clone_url_prefix)
  end

  describe 'skip?' do
    it 'skips when Geo is enabled but its a primary site' do
      stub_current_geo_node(primary_node)

      expect(subject.skip?).to be_truthy
    end

    it 'does not skip when Geo is enabled and its a secondary site' do
      expect(subject.skip?).to be_falsey
    end

    context 'with different enabled_git_access_protocol settings' do
      where(:enabled_protocol, :result) do
        [
          ['unknown', true],
          ['ssh', false],
          ['http', true],
          ['', false],
          [nil, false]
        ]
      end

      with_them do
        before do
          stub_application_setting(enabled_git_access_protocol: enabled_protocol)
        end

        it { expect(subject.skip?).to eq(result) }
      end
    end
  end

  describe '#check?' do
    context 'when the secondary site has the same port as primary' do
      before do
        stub_config(
          gitlab_shell: {
            ssh_port: primary_ssh_port,
            ssh_path_prefix: primary_clone_url_prefix
          }
        )
      end

      context 'when the primary site has a default port' do
        let(:primary_ssh_port) { 22 }
        let(:primary_clone_url_prefix) { "git@127.0.0.1" }

        it { expect(subject.check?).to be_truthy }
      end

      context 'when the primary site has a non default port' do
        it { expect(subject.check?).to be_truthy }
      end
    end

    context 'when the secondary site has different port from primary' do
      context 'when secondary site has a default port' do
        it { expect(subject.check?).to be_falsey }
      end

      context 'when secondary site has a non default port' do
        before do
          stub_config(
            gitlab_shell: {
              ssh_port: 5678,
              ssh_path_prefix: 'ssh://git@127.0.0.1:5678'
            }
          )
        end

        context 'when the primary site has a non default port' do
          it { expect(subject.check?).to be_falsey }
        end

        context 'when the primary site has a default port' do
          let(:primary_ssh_port) { 22 }
          let(:primary_clone_url_prefix) { "git@127.0.0.1" }

          it { expect(subject.check?).to be_falsey }
        end
      end
    end
  end

  describe '#show_error' do
    context 'when secondary has a non default port' do
      before do
        stub_config(
          gitlab_shell: {
            ssh_port: 5678,
            ssh_path_prefix: 'ssh://git@127.0.0.1:5678'
          }
        )
      end

      it 'returns the geo index.md#limitations page' do
        expect(subject).to receive(:for_more_information).with('doc/administration/geo/index.md#limitations')
        expect(subject).to receive(:try_fixing_it).with(
          "This site's Git SSH port is: 5678, but the primary site's Git SSH port is: 1234.",
          "Update this site's SSH port to match the primary's SSH port:",
          "- Omnibus GitLab: Update gitlab_rails['gitlab_shell_ssh_port'] in /etc/gitlab/gitlab.rb",
          "- GitLab Charts: See https://docs.gitlab.com/charts/charts/globals#port",
          "- GitLab Development Kit: See https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/ssh.md#change-the-listen-port-or-other-configuration"
        )

        subject.show_error
      end

      context 'when primary has a default port' do
        before do
          primary_node.update_column(:clone_url_prefix, 'git@localhost:')
        end

        it 'returns the geo index.md#limitations page' do
          expect(subject).to receive(:for_more_information).with('doc/administration/geo/index.md#limitations')
          expect(subject).to receive(:try_fixing_it).with(
            "This site's Git SSH port is: 5678, but the primary site's Git SSH port is: 22.",
            "Update this site's SSH port to match the primary's SSH port:",
            "- Omnibus GitLab: Update gitlab_rails['gitlab_shell_ssh_port'] in /etc/gitlab/gitlab.rb",
            "- GitLab Charts: See https://docs.gitlab.com/charts/charts/globals#port",
            "- GitLab Development Kit: See https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/ssh.md#change-the-listen-port-or-other-configuration"
          )

          subject.show_error
        end
      end
    end
  end
end
