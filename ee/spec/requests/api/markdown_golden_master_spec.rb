# frozen_string_literal: true

require 'spec_helper'

# See spec/fixtures/markdown/markdown_golden_master_examples.yml for documentation on how this spec works.
RSpec.describe API::Markdown, 'EE Golden Master', feature_category: :team_planning do
  include WikiHelpers

  let_it_be(:user) { create(:user, username: 'gfm_ee_user') }

  let_it_be(:group_wiki) { create(:group_wiki, user: user) }

  let_it_be(:group_wiki_page) { create(:wiki_page, wiki: group_wiki) }

  before do
    stub_group_wikis(true)
    sign_in(user)
  end

  markdown_yml_file_path = File.expand_path('../../fixtures/markdown/markdown_golden_master_examples.yml', __dir__)
  include_examples 'API::Markdown Golden Master shared context', markdown_yml_file_path do
    extend ::Gitlab::Utils::Override

    override :supported_api_contexts
    def supported_api_contexts
      super + %w(group_wiki)
    end

    override :get_url_for_api_context
    def get_url_for_api_context(api_context)
      case api_context
      when 'group_wiki'
        "/groups/#{group.full_path}/-/wikis/#{group_wiki_page.slug}/preview_markdown"
      else
        super
      end
    end
  end
end
