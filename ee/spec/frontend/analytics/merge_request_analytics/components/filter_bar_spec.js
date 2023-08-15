import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import FilterBar from 'ee/analytics/merge_request_analytics/components/filter_bar.vue';
import storeConfig from 'ee/analytics/merge_request_analytics/store';
import { MAX_LABEL_SUGGESTIONS } from 'ee/analytics/merge_request_analytics/constants';
import { mockBranches } from 'jest/vue_shared/components/filtered_search_bar/mock_data';
import {
  filterMilestones,
  filterLabels,
  filterUsers,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/mock_data';
import {
  getFilterParams,
  getFilterValues,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/test_helper';
import { WORKSPACE_PROJECT } from '~/issues/constants';
import * as commonUtils from '~/lib/utils/common_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import * as utils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import initialFiltersState from '~/vue_shared/components/filtered_search_bar/store/modules/filters/state';
import UrlSync from '~/vue_shared/components/url_sync.vue';

Vue.use(Vuex);

const sourceBranchTokenType = TOKEN_TYPE_SOURCE_BRANCH;
const targetBranchTokenType = TOKEN_TYPE_TARGET_BRANCH;
const milestoneTokenType = TOKEN_TYPE_MILESTONE;
const labelsTokenType = TOKEN_TYPE_LABEL;
const authorTokenType = TOKEN_TYPE_AUTHOR;
const assigneeTokenType = TOKEN_TYPE_ASSIGNEE;

const initialFilterBarState = {
  selectedSourceBranch: null,
  selectedTargetBranch: null,
  selectedMilestone: null,
  selectedAuthor: null,
  selectedAssignee: null,
  selectedLabelList: null,
};

const defaultParams = {
  source_branch_name: null,
  'not[source_branch_name]': null,
  target_branch_name: null,
  'not[target_branch_name]': null,
  milestone_title: null,
  'not[milestone_title]': null,
  author_username: null,
  'not[author_username]': null,
  assignee_username: null,
  'not[assignee_username]': null,
  label_name: null,
  'not[label_name]': null,
};

async function shouldMergeUrlParams(wrapper, result) {
  await nextTick();
  expect(urlUtils.mergeUrlParams).toHaveBeenCalledWith(result, window.location.href, {
    spreadArrays: true,
  });
  expect(commonUtils.historyPushState).toHaveBeenCalled();
}

const selectedBranchParams = getFilterParams(mockBranches, { prop: 'name' });
const selectedMilestoneParams = getFilterParams(filterMilestones);
const selectedLabelParams = getFilterParams(filterLabels);
const selectedUserParams = getFilterParams(filterUsers, { prop: 'name' });

const branchValues = getFilterValues(mockBranches, { prop: 'name' });
const milestoneValues = getFilterValues(filterMilestones);
const labelValues = getFilterValues(filterLabels);
const userValues = getFilterValues(filterUsers, { prop: 'name' });

describe('Filter bar', () => {
  let wrapper;
  let vuexStore;
  let mock;

  let setFiltersMock;

  const createStore = (initialState = {}) => {
    setFiltersMock = jest.fn();

    return new Vuex.Store({
      modules: {
        filters: {
          namespaced: true,
          state: {
            ...initialFiltersState(),
            ...initialState,
          },
          actions: {
            setFilters: setFiltersMock,
          },
        },
      },
    });
  };

  function createComponent(initialStore, options = {}) {
    const { type = WORKSPACE_PROJECT } = options;
    return shallowMount(FilterBar, {
      store: initialStore,
      provide: () => ({
        fullPath: 'foo',
        type,
      }),
      stubs: {
        UrlSync,
      },
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearchBar);
  const getSearchToken = (type) =>
    findFilteredSearch()
      .props('tokens')
      .find((token) => token.type === type);

  describe('default', () => {
    beforeEach(() => {
      vuexStore = createStore();
      wrapper = createComponent(vuexStore);
    });

    it('renders FilteredSearchBar component', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('passes the `terms-as-tokens` prop', () => {
      expect(findFilteredSearch().props('termsAsTokens')).toBe(true);
    });
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      vuexStore = createStore({
        branches: { data: mockBranches, target: {}, source: {} },
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
        authors: { data: userValues },
        assignees: { data: userValues },
      });
      wrapper = createComponent(vuexStore);
    });

    it('displays the milestone, label, author and assignee tokens', () => {
      const tokens = findFilteredSearch().props('tokens');
      expect(tokens).toHaveLength(6);
      [
        sourceBranchTokenType,
        targetBranchTokenType,
        milestoneTokenType,
        labelsTokenType,
        authorTokenType,
        assigneeTokenType,
      ].forEach((tokenType, index) => {
        expect(tokens[index].type).toBe(tokenType);
      });
    });

    it('provides the initial source branch token', () => {
      const { initialBranches } = getSearchToken(sourceBranchTokenType);

      expect(initialBranches).toHaveLength(mockBranches.length);
    });

    it('provides the initial target branch token', () => {
      const { initialBranches } = getSearchToken(targetBranchTokenType);

      expect(initialBranches).toHaveLength(mockBranches.length);
    });

    it('provides the initial milestone token', () => {
      const { initialMilestones } = getSearchToken(milestoneTokenType);

      expect(initialMilestones).toHaveLength(filterMilestones.length);
    });

    it('provides the initial label token', () => {
      const { initialLabels } = getSearchToken(labelsTokenType);

      expect(initialLabels).toHaveLength(filterLabels.length);
    });

    it('restricts the maximum number of label suggestions', () => {
      const { maxSuggestions } = getSearchToken(labelsTokenType);

      expect(maxSuggestions).toBe(MAX_LABEL_SUGGESTIONS);
    });

    it('provides the initial author token', () => {
      const { initialUsers } = getSearchToken(authorTokenType);

      expect(initialUsers).toHaveLength(filterUsers.length);
    });

    it('provides the initial assignee token', () => {
      const { initialUsers: initialAssignees } = getSearchToken(assigneeTokenType);

      expect(initialAssignees).toHaveLength(filterUsers.length);
    });
  });

  describe('when the user interacts', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
      });
      wrapper = createComponent(vuexStore);
      jest.spyOn(utils, 'processFilters');
    });

    it('clicks on the search button, setFilters is dispatched', () => {
      const filters = [
        {
          type: TOKEN_TYPE_SOURCE_BRANCH,
          value: getFilterParams(mockBranches, { key: 'data', prop: 'name' })[2],
        },
        {
          type: TOKEN_TYPE_TARGET_BRANCH,
          value: getFilterParams(mockBranches, { key: 'data', prop: 'name' })[0],
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          value: getFilterParams(filterMilestones, { key: 'data' })[2],
        },
        { type: TOKEN_TYPE_LABEL, value: getFilterParams(filterLabels, { key: 'data' })[2] },
        { type: TOKEN_TYPE_LABEL, value: getFilterParams(filterLabels, { key: 'data' })[4] },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          value: getFilterParams(filterUsers, { key: 'data', prop: 'name' })[2],
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          value: getFilterParams(filterUsers, { key: 'data', prop: 'name' })[1],
        },
      ];

      findFilteredSearch().vm.$emit('onFilter', filters);

      expect(utils.processFilters).toHaveBeenCalledWith(filters);

      expect(setFiltersMock).toHaveBeenCalledWith(expect.anything(), {
        selectedSourceBranch: selectedBranchParams[2],
        selectedTargetBranch: selectedBranchParams[0],
        selectedMilestone: selectedMilestoneParams[2],
        selectedLabelList: [selectedLabelParams[2], selectedLabelParams[4]],
        selectedAssignee: selectedUserParams[2],
        selectedAuthor: selectedUserParams[1],
      });
    });
  });

  describe.each`
    stateKey                  | payload                       | paramKey                | value
    ${'selectedSourceBranch'} | ${selectedBranchParams[1]}    | ${'source_branch_name'} | ${branchValues[1]}
    ${'selectedTargetBranch'} | ${selectedBranchParams[2]}    | ${'target_branch_name'} | ${branchValues[2]}
    ${'selectedMilestone'}    | ${selectedMilestoneParams[3]} | ${'milestone_title'}    | ${milestoneValues[3]}
    ${'selectedMilestone'}    | ${selectedMilestoneParams[0]} | ${'milestone_title'}    | ${milestoneValues[0]}
    ${'selectedLabelList'}    | ${selectedLabelParams}        | ${'label_name'}         | ${labelValues}
    ${'selectedLabelList'}    | ${selectedLabelParams}        | ${'label_name'}         | ${labelValues}
    ${'selectedAuthor'}       | ${selectedUserParams[0]}      | ${'author_username'}    | ${userValues[0]}
    ${'selectedAssignee'}     | ${selectedUserParams[1]}      | ${'assignee_username'}  | ${userValues[1]}
  `(
    'with a $stateKey updates the $paramKey url parameter',
    ({ stateKey, payload, paramKey, value }) => {
      beforeEach(() => {
        commonUtils.historyPushState = jest.fn();
        urlUtils.mergeUrlParams = jest.fn();

        mock = new MockAdapter(axios);
        wrapper = createComponent(storeConfig);

        wrapper.vm.$store.dispatch('filters/setFilters', {
          ...initialFilterBarState,
          [stateKey]: payload,
        });
      });
      it(`sets the ${paramKey} url parameter`, async () => {
        await shouldMergeUrlParams(wrapper, {
          ...defaultParams,
          [paramKey]: value,
        });
      });
    },
  );
});
