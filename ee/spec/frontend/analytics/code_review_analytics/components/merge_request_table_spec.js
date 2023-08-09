import { GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MergeRequestTable from 'ee/analytics/code_review_analytics/components/merge_request_table.vue';
import createState from 'ee/analytics/code_review_analytics/store/modules/merge_requests/state';
import { mockMergeRequests } from '../mock_data';

Vue.use(Vuex);

describe('MergeRequestTable component', () => {
  let wrapper;
  let vuexStore;

  const createStore = (initialState = {}) =>
    new Vuex.Store({
      modules: {
        mergeRequests: {
          namespaced: true,
          state: {
            ...createState(),
            ...initialState,
          },
        },
      },
    });

  const createComponent = (store) =>
    mount(MergeRequestTable, {
      store,
    });

  const bootstrap = (initialState) => {
    vuexStore = createStore(initialState);
    wrapper = createComponent(vuexStore);
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableRow = (index) => findTable().findAll('tbody tr').at(index);
  const findReviewTimeCol = (rowIndex) => findTableRow(rowIndex).findAll('td').at(1);

  const updateMergeRequests = (index, attrs) =>
    mockMergeRequests.map((item, idx) => {
      if (idx !== index) {
        return item;
      }

      return {
        ...item,
        ...attrs,
      };
    });

  describe('template', () => {
    beforeEach(() => {
      bootstrap({ mergeRequests: mockMergeRequests });
    });

    it('renders the GlTable component', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders the correct table headers', () => {
      const tableHeaders = [
        'Merge Request',
        'Review time',
        'Author',
        'Approvers',
        'Comments',
        'Commits',
        'Line changes',
      ];
      const headers = findTable().findAll('th');

      expect(headers).toHaveLength(tableHeaders.length);

      tableHeaders.forEach((headerText, i) => expect(headers.at(i).text()).toEqual(headerText));
    });

    describe('review time column', () => {
      it('shows "days" when the review time is >= 24', () => {
        bootstrap({ mergeRequests: updateMergeRequests(0, { review_time: 64 }) });

        expect(findReviewTimeCol(0).text()).toBe('2 days');
      });

      it('shows "hours" when review time is < 24', () => {
        bootstrap({ mergeRequests: updateMergeRequests(0, { review_time: 18 }) });

        expect(findReviewTimeCol(0).text()).toBe('18 hours');
      });

      it('shows "< 1 hour" when review time is < 1', () => {
        bootstrap({ mergeRequests: updateMergeRequests(0, { review_time: 0 }) });

        expect(findReviewTimeCol(0).text()).toBe('< 1 hour');
      });

      it('shows "-" when review time is null', () => {
        bootstrap({ mergeRequests: updateMergeRequests(0, { review_time: null }) });

        expect(findReviewTimeCol(0).text()).toBe('–');
      });
    });
  });
});
