import getStateKey from 'ee/vue_merge_request_widget/stores/get_state_key';

describe('getStateKey', () => {
  const canMergeContext = {
    canMerge: true,
    commitsCount: 2,
  };

  describe('jiraAssociationMissing', () => {
    const createContext = (enforced, hasIssues) => ({
      ...canMergeContext,
      jiraAssociation: {
        enforced,
        issue_keys: hasIssues ? [1] : [],
      },
    });

    it.each`
      scenario                         | enforced | hasIssues | state
      ${'enforced with issues'}        | ${true}  | ${true}   | ${'checking'}
      ${'enforced without issues'}     | ${true}  | ${false}  | ${'jiraAssociationMissing'}
      ${'not enforced with issues'}    | ${false} | ${true}   | ${'checking'}
      ${'not enforced without issues'} | ${false} | ${false}  | ${'checking'}
    `('when $scenario, state should equal $state', ({ enforced, hasIssues, state }) => {
      const bound = getStateKey.bind(createContext(enforced, hasIssues));

      expect(bound()).toBe(state);
    });
  });
});
