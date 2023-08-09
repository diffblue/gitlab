import { GlLoadingIcon, GlEmptyState, GlBadge, GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import CodeReviewAnalyticsApp from 'ee/analytics/code_review_analytics/components/app.vue';
import FilterBar from 'ee/analytics/code_review_analytics/components/filter_bar.vue';
import MergeRequestTable from 'ee/analytics/code_review_analytics/components/merge_request_table.vue';
import * as actions from 'ee/analytics/code_review_analytics/store/actions';
import createMergeRequestsState from 'ee/analytics/code_review_analytics/store/modules/merge_requests/state';
import { TEST_HOST } from 'helpers/test_constants';
import createFiltersState from '~/vue_shared/components/filtered_search_bar/store/modules/filters/state';

Vue.use(Vuex);

describe('CodeReviewAnalyticsApp component', () => {
  let wrapper;
  let vuexStore;

  let setPage;
  let fetchMergeRequests;

  const pageInfo = {
    page: 1,
    perPage: 10,
    total: 50,
  };

  const createStore = (initialState = {}, getters = {}) =>
    new Vuex.Store({
      actions,
      modules: {
        mergeRequests: {
          namespaced: true,
          state: {
            ...createMergeRequestsState(),
            ...initialState.mergeRequests,
          },
          actions: {
            setProjectId: jest.fn(),
            setPage,
            fetchMergeRequests,
          },
          getters: {
            showMrCount: () => false,
            ...getters,
          },
        },
        filters: {
          namespaced: true,
          state: {
            ...createFiltersState(),
            ...initialState.filters,
          },
        },
      },
    });

  const createComponent = (store) =>
    shallowMount(CodeReviewAnalyticsApp, {
      store,
      propsData: {
        projectId: 1,
        newMergeRequestUrl: 'new_merge_request',
        emptyStateSvgPath: 'svg',
        milestonePath: `${TEST_HOST}/milestones`,
        projectPath: TEST_HOST,
        labelsPath: `${TEST_HOST}/labels`,
      },
    });

  beforeEach(() => {
    setPage = jest.fn();
    fetchMergeRequests = jest.fn();
  });

  const findFilterBar = () => wrapper.findComponent(FilterBar);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findMrTable = () => wrapper.findComponent(MergeRequestTable);
  const findPagination = () => wrapper.findComponent(GlPagination);

  describe('template', () => {
    it('renders the filter bar component', () => {
      vuexStore = createStore();
      wrapper = createComponent(vuexStore, true);

      expect(findFilterBar().exists()).toBe(true);
    });

    describe('while loading', () => {
      beforeEach(() => {
        vuexStore = createStore({ mergeRequests: { isLoading: true } });
        wrapper = createComponent(vuexStore);
      });

      it('should display a loading indicator', () => {
        expect(findLoadingIcon().isVisible()).toBe(true);
      });

      it('should not show the badge containing the MR count', () => {
        expect(findBadge().exists()).toBe(false);
      });

      it('should not render the merge requests table', () => {
        expect(findMrTable().exists()).toBe(false);
      });

      it('should not render the pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when finished loading', () => {
      describe('and there are no merge requests', () => {
        beforeEach(() => {
          vuexStore = createStore(
            { mergeRequests: { isLoading: false, pageInfo: { page: 0, perPage: 0, total: 0 } } },
            { showMrCount: () => true },
          );
          wrapper = createComponent(vuexStore);
        });

        it('should hide the loading indicator', () => {
          expect(findLoadingIcon().isVisible()).toBe(false);
        });

        it('should show the empty state screen', () => {
          expect(findEmptyState().exists()).toBe(true);
        });

        it('should not show the badge containing the MR count', () => {
          expect(findBadge().exists()).toBe(false);
        });

        it('should not render the merge requests table', () => {
          expect(findMrTable().exists()).toBe(false);
        });

        it('should not render the pagination', () => {
          expect(findPagination().exists()).toBe(false);
        });
      });

      describe('and there are merge requests', () => {
        beforeEach(() => {
          vuexStore = createStore(
            { mergeRequests: { isLoading: false, pageInfo } },
            { showMrCount: () => true },
          );
          wrapper = createComponent(vuexStore);
        });

        it('should hide the loading indicator', () => {
          expect(findLoadingIcon().isVisible()).toBe(false);
        });

        it('should show the badge containing the MR count', () => {
          expect(findBadge().exists()).toBe(true);
          expect(findBadge().text()).toBe('50');
        });

        it('should not render the empty state screen', () => {
          expect(findEmptyState().exists()).toBe(false);
        });

        it('should render the merge requests table', () => {
          expect(findMrTable().exists()).toBe(true);
        });

        it('should render the pagination', () => {
          expect(findPagination().exists()).toBe(true);
        });
      });
    });
  });

  describe('changing the page', () => {
    beforeEach(async () => {
      vuexStore = createStore(
        { mergeRequests: { isLoading: false, pageInfo } },
        { showMrCount: () => true },
      );
      wrapper = createComponent(vuexStore);

      findPagination().vm.$emit('input', 2);
      await nextTick();
    });

    it('should call the setPage action', () => {
      expect(setPage).toHaveBeenCalledWith(expect.anything(), 2);
    });

    it('should call fetchMergeRequests action', () => {
      expect(fetchMergeRequests).toHaveBeenCalledTimes(2);
    });
  });
});
