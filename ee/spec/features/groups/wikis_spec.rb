# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Group wikis', :js, feature_category: :wiki do
  include WikiHelpers

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:wiki) { create(:group_wiki, user: user, group: group) }

  before do
    stub_group_wikis(true)
    wiki.container.add_owner(user)
  end

  it_behaves_like 'User creates wiki page'
  it_behaves_like 'User deletes wiki page'
  it_behaves_like 'User previews wiki changes'
  it_behaves_like 'User updates wiki page'
  it_behaves_like 'User uses wiki shortcuts'
  it_behaves_like 'User views AsciiDoc page with includes'
  it_behaves_like 'User views a wiki page'
  it_behaves_like 'User views wiki pages'
  it_behaves_like 'User views wiki sidebar'
  it_behaves_like 'User views Git access wiki page'
end
