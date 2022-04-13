# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiHelper do
  describe '#wiki_attachment_upload_url' do
    it 'returns the upload endpoint for group wikis' do
      @wiki = build_stubbed(:group_wiki)

      expect(helper.wiki_attachment_upload_url).to end_with("/api/v4/groups/#{@wiki.group.id}/wikis/attachments")
    end
  end

  it_behaves_like 'wiki endpoint helpers' do
    let_it_be(:page) { create(:wiki_page, wiki: create(:group_wiki)) }
  end
end
