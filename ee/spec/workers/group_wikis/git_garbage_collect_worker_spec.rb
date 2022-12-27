# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupWikis::GitGarbageCollectWorker, feature_category: :source_code_management do
  it_behaves_like 'can collect git garbage', update_statistics: false do
    let_it_be(:resource) { create(:group_wiki) }
    let_it_be(:page) { create(:wiki_page, wiki: resource) }
    let_it_be(:statistics_keys) { [] }

    let(:expected_default_lease) { "group_wikis:#{resource.id}" }
  end
end
