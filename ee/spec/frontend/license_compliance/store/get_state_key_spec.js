import getStateKey from 'ee/vue_merge_request_widget/stores/get_state_key';
import {
  DETAILED_MERGE_STATUS,
  MWCP_MERGE_STRATEGY,
  MWPS_MERGE_STRATEGY,
} from '~/vue_merge_request_widget/constants';

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

  describe('AutoMergeStrategy "merge_when_checks_pass"', () => {
    const createContext = (detailedMergeStatus, preferredAutoMergeStrategy, autoMergeEnabled) => ({
      ...canMergeContext,
      detailedMergeStatus,
      preferredAutoMergeStrategy,
      autoMergeEnabled,
    });

    it.each`
      scenario                                      | detailedMergeStatus                   | preferredAutoMergeStrategy | autoMergeEnabled | state
      ${'MWCP and not approved'}                    | ${DETAILED_MERGE_STATUS.NOT_APPROVED} | ${MWCP_MERGE_STRATEGY}     | ${false}         | ${'readyToMerge'}
      ${'MWCP, not approved and autoMerge enabled'} | ${DETAILED_MERGE_STATUS.NOT_APPROVED} | ${MWCP_MERGE_STRATEGY}     | ${true}          | ${'autoMergeEnabled'}
      ${'MWCP and approved'}                        | ${DETAILED_MERGE_STATUS.MERGEABLE}    | ${MWCP_MERGE_STRATEGY}     | ${false}         | ${'readyToMerge'}
      ${'MWPS and not approved'}                    | ${DETAILED_MERGE_STATUS.NOT_APPROVED} | ${MWPS_MERGE_STRATEGY}     | ${false}         | ${'checking'}
    `(
      'when $scenario, state should equal $state',
      ({ detailedMergeStatus, preferredAutoMergeStrategy, autoMergeEnabled, state }) => {
        const bound = getStateKey.bind(
          createContext(detailedMergeStatus, preferredAutoMergeStrategy, autoMergeEnabled),
        );

        expect(bound()).toBe(state);
      },
    );
  });
});
