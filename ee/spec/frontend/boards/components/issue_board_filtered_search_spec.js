import { shallowMount } from '@vue/test-utils';
import { orderBy } from 'lodash';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import IssueBoardFilteredSpec from 'ee/boards/components/issue_board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { mockTokens } from '../mock_data';

jest.mock('~/boards/issue_board_filters');

describe('IssueBoardFilter', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(IssueBoardFilteredSpec, {
      provide: {
        isSignedIn: true,
        releasesFetchPath: '/releases',
        fullPath: 'gitlab-org',
        boardType: 'group',
        epicFeatureAvailable: true,
        iterationFeatureAvailable: true,
        healthStatusFeatureAvailable: true,
      },
    });
  };

  let fetchUsersSpy;
  let fetchLabelsSpy;
  beforeEach(() => {
    fetchUsersSpy = jest.fn();
    fetchLabelsSpy = jest.fn();

    issueBoardFilters.mockReturnValue({
      fetchUsers: fetchUsersSpy,
      fetchLabels: fetchLabelsSpy,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('finds BoardFilteredSearch', () => {
      expect(wrapper.findComponent(BoardFilteredSearch).exists()).toBe(true);
    });

    it('passes the correct tokens to BoardFilteredSearch including epics', () => {
      const tokens = mockTokens(
        fetchLabelsSpy,
        fetchUsersSpy,
        wrapper.vm.fetchMilestones,
        wrapper.vm.fetchIterations,
        wrapper.vm.fetchIterationCadences,
      );

      expect(wrapper.findComponent(BoardFilteredSearch).props('tokens')).toEqual(
        orderBy(tokens, ['title']),
      );
    });
  });
});
