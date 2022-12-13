# frozen_string_literal: true

require 'spec_helper'

# For every API endpoint we test 3 states of wikis:
# - disabled
# - enabled only for team members
# - enabled for everyone who has access
# Every state is tested for 3 user roles:
# - guest
# - developer
# - maintainer
# because they are 3 edge cases of using wiki pages.

RSpec.describe API::Wikis, feature_category: :wiki do
  include WikiHelpers
  include WorkhorseHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group, :internal, :wiki_repo) }
  let(:wiki) { create(:group_wiki, container: group, user: user) }
  let(:payload) { { content: 'content', format: 'rdoc', title: 'title' } }
  let(:expected_keys_with_content) { %w(content format slug title encoding) }
  let(:expected_keys_without_content) { %w(format slug title) }

  before do
    stub_group_wikis(true)
  end

  shared_examples_for 'wiki API 404 Group Not Found' do
    include_examples 'wiki API 404 Not Found', 'Group'
  end

  describe 'GET /groups/:id/wikis' do
    let(:url) { "/groups/#{group.id}/wikis" }

    context 'when group wiki is disabled' do
      before do
        stub_group_wikis(false)
      end

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)

          get api(url, user)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)

          get api(url, user)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    # Skipped pending https://gitlab.com/gitlab-org/gitlab/-/issues/208412
    xcontext 'when wiki is available only for team members' do
      let(:group) { create(:group, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end
    end

    context 'when wiki is available for everyone with access' do
      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API returns list of wiki pages'
      end
    end
  end

  describe 'GET /groups/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: wiki) }
    let(:url) { "/groups/#{group.id}/wikis/#{page.slug}" }
    let(:params) { {} }

    context 'when wiki is disabled' do
      before do
        stub_group_wikis(false)
      end

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)

          get api(url, user)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)

          get api(url, user)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    # Skipped pending https://gitlab.com/gitlab-org/gitlab/-/issues/208412
    xcontext 'when wiki is available only for team members' do
      let(:group) { create(:group, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            get api(url, user), params: params
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            get api(url, user), params: params
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki is available for everyone with access' do
      context 'when user is guest' do
        before do
          get api(url)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            get api(url, user), params: params
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API returns wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            get api(url, user), params: params
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end
  end

  describe 'POST /groups/:id/wikis' do
    let(:payload) { { title: 'title', content: 'content' } }
    let(:url) { "/groups/#{group.id}/wikis" }

    context 'when wiki is disabled' do
      before do
        stub_group_wikis(false)
      end

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
          post(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
          post(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    xcontext 'when wiki is available only for team members' do
      let(:group) { create(:group, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API creates wiki page'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API creates wiki page'
      end
    end

    context 'when wiki is available for everyone with access' do
      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API creates wiki page'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API creates wiki page'
      end
    end
  end

  describe 'PUT /group/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: wiki) }
    let(:payload) { { title: 'new title', content: 'new content' } }
    let(:url) { "/groups/#{group.id}/wikis/#{page.slug}" }

    context 'when wiki is disabled' do
      before do
        stub_group_wikis(false)
      end

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)

          put(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)

          put(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    xcontext 'when wiki is available only for team members' do
      let(:group) { create(:group, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page is not existing' do
          let(:url) { "/group/#{group.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when wiki is available for everyone with access' do
      context 'when user is guest' do
        before do
          put(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wikis API updates wiki page'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          before do
            put(api(url, user), params: payload)
          end

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when user is owner of parent group' do
      let_it_be(:namespace) { create(:group).tap { |g| g.add_owner(user) } }
      let_it_be(:group) { create(:group, :wiki_repo, parent: namespace) }

      include_examples 'wikis API updates wiki page'
    end
  end

  describe 'DELETE /groups/:id/wikis/:slug' do
    let(:page) { create(:wiki_page, wiki: wiki) }
    let(:url) { "/groups/#{group.id}/wikis/#{page.slug}" }

    context 'when wiki is disabled' do
      before do
        stub_group_wikis(false)
      end

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    # Skipped pending https://gitlab.com/gitlab-org/gitlab/-/issues/208412
    xcontext 'when wiki is available only for team members' do
      let(:group) { create(:group, :wiki_repo, :wiki_private) }

      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 204 No Content'
      end
    end

    context 'when wiki is available for everyone with access' do
      context 'when user is guest' do
        before do
          delete(api(url))
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)

          delete(api(url, user))
        end

        include_examples 'wiki API 204 No Content'

        context 'when page does not exist' do
          let(:url) { "/groups/#{group.id}/wikis/unknown" }

          include_examples 'wiki API 404 Wiki Page Not Found'
        end
      end
    end

    context 'when user is owner of parent group' do
      let_it_be(:namespace) { create(:group).tap { |g| g.add_owner(user) } }
      let_it_be(:group) { create(:group, :wiki_repo, parent: namespace) }

      before do
        delete(api(url, user))
      end

      include_examples 'wiki API 204 No Content'
    end
  end

  describe 'POST /groups/:id/wikis/attachments' do
    let(:payload) { { file: fixture_file_upload('spec/fixtures/dk.png') } }
    let(:url) { "/groups/#{group.id}/wikis/attachments" }
    let(:file_path) { "#{Wikis::CreateAttachmentService::ATTACHMENT_PATH}/fixed_hex/dk.png" }
    let(:result_hash) do
      {
        file_name: 'dk.png',
        file_path: file_path,
        branch: 'master',
        link: {
          url: file_path,
          markdown: "![dk](#{file_path})"
        }
      }
    end

    context 'when wiki is disabled' do
      before do
        stub_group_wikis(false)
      end

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
          post(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
          post(api(url, user), params: payload)
        end

        include_examples 'wiki API 403 Forbidden'
      end
    end

    # Skipped pending https://gitlab.com/gitlab-org/gitlab/-/issues/208412
    xcontext 'when wiki is available only for team members' do
      let(:group) { create(:group, :wiki_private, :wiki_repo) }

      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end
    end

    context 'when wiki is available for everyone with access' do
      context 'when user is guest' do
        before do
          post(api(url), params: payload)
        end

        include_examples 'wiki API 404 Group Not Found'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        include_examples 'wiki API uploads wiki attachment'
      end
    end
  end
end
