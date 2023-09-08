import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import FilteredSearchIssueAnalytics from 'ee/issues_analytics/filtered_search_issues_analytics';
import IssuableFilteredSearchTokenKeys from 'ee/filtered_search/issuable_filtered_search_token_keys';

describe('FilteredSearchIssueAnalytics', () => {
  describe('Token keys', () => {
    const fixture = `<div class="filtered-search-box-input-container"><input class="filtered-search" /></div>`;
    let component;
    let availableTokens;
    let enableMultipleAssigneesSpy;

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
      expectedTokenKeys           | shouldHideNotEqual | shouldEnableMultipleAssignees | issuesCompletedAnalyticsFeatureFlag | hasIssuesCompletedFeature
      ${defaultTokenKeys}         | ${false}           | ${false}                      | ${false}                            | ${false}
      ${defaultTokenKeys}         | ${false}           | ${false}                      | ${false}                            | ${true}
      ${defaultTokenKeys}         | ${false}           | ${false}                      | ${true}                             | ${false}
      ${issuesCompletedTokenKeys} | ${true}            | ${true}                       | ${true}                             | ${true}
    `(
      'when issuesCompletedAnalyticsFeatureFlag=$issuesCompletedAnalyticsFeatureFlag and hasIssuesCompletedFeature=$hasIssuesCompletedFeature',
      ({
        expectedTokenKeys,
        issuesCompletedAnalyticsFeatureFlag,
        hasIssuesCompletedFeature,
        shouldHideNotEqual,
        shouldEnableMultipleAssignees,
      }) => {
        beforeEach(() => {
          gon.features = { issuesCompletedAnalyticsFeatureFlag };

          setHTMLFixture(fixture);

          enableMultipleAssigneesSpy = jest
            .spyOn(IssuableFilteredSearchTokenKeys, 'enableMultipleAssignees')
            .mockImplementation();
          component = new FilteredSearchIssueAnalytics({ hasIssuesCompletedFeature });
          availableTokens = component.filteredSearchTokenKeys;
        });

        afterEach(() => {
          component = null;

          resetHTMLFixture();
          enableMultipleAssigneesSpy.mockRestore();
        });

        it('should only include the supported token keys', () => {
          const availableTokenKeys = availableTokens.getKeys();

          expect(availableTokenKeys).toEqual(expectedTokenKeys);
        });

        it(`should ${shouldHideNotEqual ? '' : 'not'} hide 'notEqual' operators`, () => {
          const hasNotEqualOperators = availableTokens
            .get()
            .every(({ hideNotEqual }) => hideNotEqual);

          expect(hasNotEqualOperators).toBe(shouldHideNotEqual);
        });

        it(`should ${shouldEnableMultipleAssignees ? '' : 'not'} enable multiple assignees`, () => {
          expect(enableMultipleAssigneesSpy).toHaveBeenCalledTimes(
            shouldEnableMultipleAssignees ? 1 : 0,
          );
        });
      },
    );
  });
});
