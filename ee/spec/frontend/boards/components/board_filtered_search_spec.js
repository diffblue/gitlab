import { shallowMount } from '@vue/test-utils';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import BoardFilteredSearchCe from '~/boards/components/board_filtered_search.vue';

describe('ee/BoardFilteredSearch', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(BoardFilteredSearch, { propsData: { tokens: [] } });
  };

  const findFilteredSearch = () => wrapper.findComponent(BoardFilteredSearchCe);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders FilteredSearch', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });
  });
});
