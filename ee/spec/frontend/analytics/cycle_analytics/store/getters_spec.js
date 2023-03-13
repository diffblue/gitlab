import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import {
  createdAfter,
  createdBefore,
  selectedProjects,
  groupNamespace as namespace,
} from 'jest/analytics/cycle_analytics/mock_data';
import {
  filterMilestones,
  filterUsers,
  filterLabels,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/mock_data';
import {
  getFilterParams,
  getFilterValues,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/test_helper';
import {
  allowedStages,
  issueStage,
  stageMediansWithNumericIds,
  stageCounts,
  transformedStagePathData,
} from '../mock_data';

let state = null;

const selectedMilestoneParams = getFilterParams(filterMilestones);
const selectedLabelParams = getFilterParams(filterLabels);
const selectedUserParams = getFilterParams(filterUsers, { prop: 'name' });

const milestoneValues = getFilterValues(filterMilestones);
const labelValues = getFilterValues(filterLabels);
const userValues = getFilterValues(filterUsers, { prop: 'name' });
const { fullPath } = namespace;

describe('Value Stream Analytics getters', () => {
  describe('hasNoAccessError', () => {
    beforeEach(() => {
      state = {
        errorCode: null,
      };
    });

    it('returns true if "hasError" is set to 403', () => {
      state.errorCode = HTTP_STATUS_FORBIDDEN;
      expect(getters.hasNoAccessError(state)).toEqual(true);
    });

    it('returns false if "hasError" is not set to 403', () => {
      expect(getters.hasNoAccessError(state)).toEqual(false);
    });
  });

  describe('selectedProjectIds', () => {
    describe('with selectedProjects set', () => {
      it('returns the ids of each project', () => {
        state = {
          selectedProjects,
        };

        expect(getters.selectedProjectIds(state)).toEqual([1, 2]);
      });
    });

    describe('without selectedProjects set', () => {
      it('will return an empty array', () => {
        state = { selectedProjects: [] };
        expect(getters.selectedProjectIds(state)).toEqual([]);
      });
    });
  });

  describe('namespacePath', () => {
    describe('with namespace set', () => {
      it('returns the `fullPath` value of the group', () => {
        state = {
          namespace,
        };

        expect(getters.namespacePath(state)).toEqual(fullPath);
      });
    });

    describe('without a namespace set', () => {
      it.each([[''], [{}], [null]])('given "%s" will return null', (value) => {
        state = { namespace: value };
        expect(getters.namespacePath(state)).toEqual(null);
      });
    });
  });

  describe('cycleAnalyticsRequestParams', () => {
    beforeEach(() => {
      state = {
        namespace,
        createdAfter,
        createdBefore,
        selectedProjects,
        filters: {
          authors: { selected: selectedUserParams[0] },
          milestones: { selected: selectedMilestoneParams[1] },
          assignees: { selectedList: selectedUserParams[1] },
          labels: { selectedList: selectedLabelParams },
        },
      };
    });

    it.each`
      param                  | value
      ${'created_after'}     | ${'2018-12-15'}
      ${'created_before'}    | ${'2019-01-14'}
      ${'project_ids'}       | ${[1, 2]}
      ${'author_username'}   | ${userValues[0]}
      ${'milestone_title'}   | ${milestoneValues[1]}
      ${'assignee_username'} | ${userValues[1]}
      ${'label_name'}        | ${labelValues}
    `('should return the $param with value $value', ({ param, value }) => {
      expect(
        getters.cycleAnalyticsRequestParams(state, { selectedProjectIds: [1, 2] }),
      ).toMatchObject({
        [param]: value,
      });
    });

    it.each`
      param                  | stateKey         | value
      ${'assignee_username'} | ${'userValues'}  | ${[]}
      ${'label_name'}        | ${'labelValues'} | ${[]}
    `('should not return the $param when $stateKey=$value', ({ param, stateKey, value }) => {
      expect(
        getters.cycleAnalyticsRequestParams(
          { ...state, [stateKey]: value },
          { selectedProjectIds: [1, 2] },
        ),
      ).not.toContain(param);
    });
  });

  const hiddenStage = { ...allowedStages[2], hidden: true };
  const givenStages = [allowedStages[0], allowedStages[1], hiddenStage];
  describe.each`
    func              | givenStages    | expectedStages
    ${'hiddenStages'} | ${givenStages} | ${[hiddenStage]}
    ${'activeStages'} | ${givenStages} | ${[allowedStages[0], allowedStages[1]]}
  `('hiddenStages', ({ func, expectedStages, givenStages: stages }) => {
    it(`'${func}' returns ${expectedStages.length} stages`, () => {
      expect(getters[func]({ stages })).toEqual(expectedStages);
    });

    it(`'${func}' returns an empty array if there are no stages`, () => {
      expect(getters[func]({ stages: [] })).toEqual([]);
    });
  });

  describe.each`
    isEditingCustomStage | isCreatingCustomStage | result
    ${true}              | ${true}               | ${true}
    ${true}              | ${false}              | ${true}
    ${false}             | ${true}               | ${true}
    ${null}              | ${true}               | ${true}
    ${true}              | ${null}               | ${true}
    ${null}              | ${null}               | ${false}
    ${false}             | ${false}              | ${false}
  `('customStageFormActive', ({ isEditingCustomStage, isCreatingCustomStage, result }) => {
    it(`returns ${result} when isEditingCustomStage=${isEditingCustomStage} and isCreatingCustomStage=${isCreatingCustomStage}`, () => {
      const resp = getters.customStageFormActive({ isCreatingCustomStage, isEditingCustomStage });
      expect(resp).toEqual(result);
    });
  });

  describe('pathNavigationData', () => {
    it('returns the transformed data', () => {
      state = {
        stages: allowedStages,
        medians: stageMediansWithNumericIds,
        selectedStage: issueStage,
        stageCounts,
      };

      expect(getters.pathNavigationData(state)).toEqual(transformedStagePathData);
    });
  });

  describe('selectedStageCount', () => {
    it('returns the count when a value exist for the given stage', () => {
      state = { selectedStage: { id: 1 }, stageCounts: { 1: 10, 2: 20 } };
      expect(getters.selectedStageCount(state)).toEqual(10);
    });

    it('returns null if there is no value for the given stage', () => {
      state = { selectedStage: { id: 3 }, stageCounts: { 1: 10, 2: 20 } };
      expect(getters.selectedStageCount(state)).toEqual(null);
    });
  });
});
