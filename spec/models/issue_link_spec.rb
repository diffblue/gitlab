# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLink do
  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:issue_link) }
    let_it_be(:issuable) { create(:issue) }
    let(:issuable_class) { 'Issue' }
    let(:issuable_link_factory) { :issue_link }
  end
end
