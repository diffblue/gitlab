# frozen_string_literal: true

RSpec.shared_examples 'git access for a read-only GitLab instance' do
  include EE::GeoHelpers

  it 'denies push access' do
    project.add_maintainer(user)

    expect { push_changes }.to raise_forbidden("You can't push code to a read-only GitLab instance.")
  end

  context 'for a Geo setup' do
    let_it_be(:primary_node) do
      create(
        :geo_node,
        :primary,
        url: 'https://localhost:3000/gitlab',
        internal_url: 'https://localhost:3001/gitlab'
      )
    end

    let_it_be(:secondary_node) { create(:geo_node) }

    before do
      stub_licensed_features(geo: true)
    end

    context 'that is incorrectly set up' do
      let(:error_message) { "You can't push code to a read-only GitLab instance." }

      it 'denies push access with primary present' do
        project.add_maintainer(user)

        expect { push_changes }.to raise_forbidden(error_message)
      end
    end

    context 'that is correctly set up' do
      let(:console_messages) do
        [
          "This request to a Geo secondary node will be forwarded to the",
          "Geo primary node:",
          "",
          "  #{primary_repo_ssh_url}"
        ]
      end

      before do
        stub_current_geo_node(secondary_node)
      end

      context 'for a git clone/pull' do
        let(:payload) do
          {
            'action' => 'geo_proxy_to_primary',
            'data' => {
              'api_endpoints' => %w{/api/v4/geo/proxy_git_ssh/info_refs_upload_pack /api/v4/geo/proxy_git_ssh/upload_pack},
              'primary_repo' => primary_repo_url,
              "geo_proxy_direct_to_primary" => true,
              "request_headers" => include('Authorization')
            }
          }
        end

        it 'attempts to proxy to the primary' do
          project.add_maintainer(user)

          expect(pull_changes).to be_a(Gitlab::GitAccessResult::CustomAction)
          expect(pull_changes.payload).to include(payload)
          expect(pull_changes.console_messages).to include(*console_messages)
        end
      end

      context 'for a git push' do
        let(:payload) do
          {
            'action' => 'geo_proxy_to_primary',
            'data' => {
              'api_endpoints' => %w{/api/v4/geo/proxy_git_ssh/info_refs_receive_pack /api/v4/geo/proxy_git_ssh/receive_pack},
              'primary_repo' => primary_repo_url,
              "geo_proxy_direct_to_primary" => true,
              "request_headers" => include('Authorization')
            }
          }
        end

        it 'attempts to proxy to the primary' do
          project.add_maintainer(user)

          expect(push_changes).to be_a(Gitlab::GitAccessResult::CustomAction)
          expect(push_changes.payload).to include(payload)
          expect(push_changes.console_messages).to include(*console_messages)
        end
      end
    end
  end
end
