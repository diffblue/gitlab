import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilteredSearchIssueAnalytics from 'ee/issues_analytics/filtered_search_issues_analytics';

describe('FilteredSearchIssueAnalytics', () => {
  describe('Token keys', () => {
    const fixture = `<div class="filtered-search-box-input-container"><input class="filtered-search" /></div>`;
    let component = null;
    let availableTokenKeys = null;

    beforeEach(() => {
      setHTMLFixture(fixture);
      component = new FilteredSearchIssueAnalytics();
      availableTokenKeys = component.filteredSearchTokenKeys.tokenKeys.map(({ key }) => key);
    });

    afterEach(() => {
      component = null;

      resetHTMLFixture();
    });

    it.each`
      token          | available
      ${'author'}    | ${true}
      ${'assignee'}  | ${true}
      ${'milestone'} | ${true}
      ${'label'}     | ${true}
      ${'epic'}      | ${true}
      ${'weight'}    | ${true}
      ${'release'}   | ${false}
    `('includes $token filter $available', ({ token, available }) => {
      expect(availableTokenKeys.includes(token)).toBe(available);
    });
  });
});
