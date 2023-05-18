import htmlCeBlobSearchResult from 'test_fixtures/search/blob_search_result.html';
import htmlEeBlobSearchResult from 'test_fixtures/ee/search/blob_search_result.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setHighlightClass from 'ee/search/highlight_blob_search_result';

const searchKeyword = 'Send'; // spec/frontend/fixtures/search.rb#79

describe('ee/search/highlight_blob_search_result', () => {
  // Basic search support
  it('highlights lines with search term occurrence', () => {
    setHTMLFixture(htmlCeBlobSearchResult);

    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.js-blob-result .hll').length).toBe(4);

    resetHTMLFixture();
  });

  // Advanced search support
  it('highlights lines which have been identified by Elasticsearch', () => {
    setHTMLFixture(htmlEeBlobSearchResult);

    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.js-blob-result .hll').length).toBe(3);

    resetHTMLFixture();
  });
});
