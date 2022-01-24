import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import BoardFilteredSearchCe from '~/boards/components/board_filtered_search.vue';
import { createStore } from '~/boards/stores';
import * as urlUtility from '~/lib/utils/url_utility';

Vue.use(Vuex);

describe('ee/BoardFilteredSearch', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    wrapper = shallowMount(BoardFilteredSearch, {
      store,
      propsData: { tokens: [] },
    });
  };

  const findFilteredSearch = () => wrapper.findComponent(BoardFilteredSearchCe);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when boardScopeConfig watcher is triggered', () => {
    beforeEach(async () => {
      store = createStore();

      createComponent();

      jest.spyOn(store, 'dispatch').mockImplementation();
      jest.spyOn(urlUtility, 'updateHistory');

      store.state.boardConfig = { labels: [{ title: 'test', color: 'black', id: '1' }] };

      await nextTick();
    });

    it('calls performSearch', () => {
      expect(store.dispatch).toHaveBeenCalledWith('performSearch');
    });

    it('calls historyPushState', () => {
      expect(urlUtility.updateHistory).toHaveBeenCalledWith({
        url: '?label_name[]=test',
      });
    });

    it('passes the correct props to BoardFilteredSearchCe', () => {
      expect(findFilteredSearch().props()).toEqual(
        expect.objectContaining({ eeFilters: { labelName: ['test'] } }),
      );
    });
  });

  describe('when resetFilters is true and boardConfig is not empty', () => {
    beforeEach(() => {
      store = createStore();

      createComponent();
    });

    it('renders BoardFilteredSearchCe', async () => {
      store.state.boardConfig = {};

      await nextTick();

      expect(findFilteredSearch().exists()).toEqual(false);

      store.state.boardConfig = { labels: [] };

      await nextTick();

      expect(findFilteredSearch().exists()).toBe(true);
    });
  });
});
