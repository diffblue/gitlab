# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::SnippetSearchResults, :elastic_clean, :clean_gitlab_redis_shared_state, :sidekiq_might_not_need_inline do
  let(:snippet) { create(:personal_snippet, title: 'foo', description: 'foo') }
  let(:results) { described_class.new(snippet.author, 'foo', []) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    perform_enqueued_jobs { snippet }
    ensure_elasticsearch_index!
  end

  describe 'pagination' do
    let(:snippet2) { create(:personal_snippet, title: 'foo 2', author: snippet.author) }

    before do
      perform_enqueued_jobs { snippet2 }
      ensure_elasticsearch_index!
    end

    it 'returns the correct page of results' do
      # `snippet` is more relevant than `snippet2` (hence first in order) due
      # to having a shorter title that exactly matches the query and also due
      # to having a description that matches the query.
      expect(results.objects('snippet_titles', page: 1, per_page: 1)).to eq([snippet])
      expect(results.objects('snippet_titles', page: 2, per_page: 1)).to eq([snippet2])
    end

    it 'returns the correct number of results for one page' do
      expect(results.objects('snippet_titles', page: 1, per_page: 2)).to eq([snippet, snippet2])
    end
  end

  describe '#snippet_titles_count' do
    it 'returns the amount of matched snippet titles' do
      expect(results.snippet_titles_count).to eq(1)
    end
  end

  describe '#formatted_count' do
    using RSpec::Parameterized::TableSyntax

    where(:value, :expected) do
      1     | '1'
      9999  | '9,999'
      10000 | '10,000+'
      20000 | '10,000+'
      0     | '0'
      nil   | '0'
    end

    with_them do
      it 'returns the expected formatted count limited and delimited' do
        expect(results).to receive(:snippet_titles_count).and_return(value)
        expect(results.formatted_count('snippets')).to eq(expected)
      end
    end
  end

  describe '#highlight_map' do
    it 'returns the expected highlight map' do
      expect(results).to receive(:snippet_titles).and_return([{ _source: { id: 1 }, highlight: 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }])
      expect(results.highlight_map('snippet_titles')).to eq({ 1 => 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' })
    end
  end

  context 'when user is not author' do
    let(:results) { described_class.new(create(:user), 'foo', []) }

    it 'returns nothing' do
      expect(results.snippet_titles_count).to eq(0)
    end
  end

  context 'when user is nil' do
    let(:results) { described_class.new(nil, 'foo', []) }

    it 'returns nothing' do
      expect(results.snippet_titles_count).to eq(0)
    end

    context 'when snippet is public' do
      let(:snippet) { create(:personal_snippet, :public, title: 'foo', description: 'foo') }

      it 'returns public snippet' do
        expect(results.snippet_titles_count).to eq(1)
      end
    end
  end

  context 'when user has read_all_resources' do
    include_context 'custom session'

    let(:user) { create(:admin) }
    let(:results) { described_class.new(user, 'foo', :any) }

    context 'admin mode disabled' do
      it 'returns nothing' do
        expect(results.snippet_titles_count).to eq(0)
      end
    end

    context 'admin mode enabled' do
      before do
        Gitlab::Auth::CurrentUserMode.new(user).request_admin_mode!
        Gitlab::Auth::CurrentUserMode.new(user).enable_admin_mode!(password: user.password)
      end

      it 'returns matched snippets' do
        expect(results.snippet_titles_count).to eq(1)
      end
    end
  end
end
