import setHighlightClass from 'ee/search/highlight_blob_search_result';

const fixture = 'ee/search/blob_search_result.html';
const ceFixture = 'search/blob_search_result.html';
const searchKeyword = 'Send'; // spec/frontend/fixtures/search.rb#79

describe('ee/search/highlight_blob_search_result', () => {
  // Basic search support
  it('highlights lines with search term occurrence', () => {
    loadFixtures(ceFixture);

    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.js-blob-result .hll').length).toBe(4);
  });

  // Advanced search support
  it('highlights lines which have been identified by Elasticsearch', () => {
    loadFixtures(fixture);

    setHighlightClass(searchKeyword);

    expect(document.querySelectorAll('.js-blob-result .hll').length).toBe(3);
  });
});
