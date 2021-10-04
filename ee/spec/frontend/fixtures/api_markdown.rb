# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequests, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include WikiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:user) { create(:user) }

  let_it_be(:group) { create(:group, :public) }

  let_it_be(:group_wiki) { create(:group_wiki, user: user) }

  let(:group_wiki_page) { create(:wiki_page, wiki: group_wiki) }
  let(:project_wiki_page) { create(:wiki_page, wiki: project_wiki) }

  before(:all) do
    group.add_owner(user)
  end

  before do
    stub_group_wikis(true)
    sign_in(user)
  end

  markdown_examples = begin
    yaml_file_path = File.expand_path('api_markdown.yml', __dir__)
    yaml = File.read(yaml_file_path)
    YAML.safe_load(yaml, symbolize_names: true)
  end

  markdown_examples.each do |markdown_example|
    context = markdown_example.fetch(:context, '')
    name = markdown_example.fetch(:name)

    context "for #{name}#{!context.empty? ? " (context: #{context})" : ''}" do
      let(:markdown) { markdown_example.fetch(:markdown) }

      name = "#{context}_#{name}" unless context.empty?

      it "api/markdown/#{name}.json" do
        api_url = case context
                  when 'group_wiki'
                    "/groups/#{group.full_path}/-/wikis/#{group_wiki_page.slug}/preview_markdown"
                  else
                    api "/markdown"
                  end

        post api_url, params: { text: markdown, gfm: true }
        expect(response).to be_successful
      end
    end
  end
end
