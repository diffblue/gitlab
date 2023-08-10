import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilteredSearchIssueAnalytics from 'ee/issues_analytics/filtered_search_issues_analytics';

describe('FilteredSearchIssueAnalytics', () => {
  describe('Token keys', () => {
    const fixture = `<div class="filtered-search-box-input-container"><input class="filtered-search" /></div>`;
    let component = null;
    let availableTokenKeys = null;

    const defaultTokenKeys = [
      'author',
      'assignee',
      'milestone',
      'iteration', // will be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/419743
      'label',
      'epic',
      'weight',
    ];
    const issuesCompletedTokenKeys = ['author', 'assignee', 'milestone', 'label'];

    describe.each`
      expectedTokenKeys           | issuesCompletedAnalyticsFeatureFlag | hasIssuesCompletedFeature
      ${defaultTokenKeys}         | ${false}                            | ${false}
      ${defaultTokenKeys}         | ${false}                            | ${true}
      ${defaultTokenKeys}         | ${true}                             | ${false}
      ${issuesCompletedTokenKeys} | ${true}                             | ${true}
    `(
      'when issuesCompletedAnalyticsFeatureFlag=$issuesCompletedAnalyticsFeatureFlag and hasIssuesCompletedFeature=$hasIssuesCompletedFeature',
      ({ expectedTokenKeys, issuesCompletedAnalyticsFeatureFlag, hasIssuesCompletedFeature }) => {
        beforeEach(() => {
          gon.features = { issuesCompletedAnalyticsFeatureFlag };

          setHTMLFixture(fixture);
          component = new FilteredSearchIssueAnalytics({ hasIssuesCompletedFeature });
          availableTokenKeys = component.filteredSearchTokenKeys.tokenKeys.map(({ key }) => key);
        });

        afterEach(() => {
          component = null;

          resetHTMLFixture();
        });

        it('should only include the supported token keys', () => {
          expect(availableTokenKeys).toEqual(expectedTokenKeys);
        });
      },
    );
  });
});
