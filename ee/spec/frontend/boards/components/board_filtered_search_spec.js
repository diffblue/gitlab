import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import BoardFilteredSearchCe from '~/boards/components/board_filtered_search.vue';
import { createStore } from '~/boards/stores';
import * as urlUtility from '~/lib/utils/url_utility';

Vue.use(Vuex);

describe('ee/BoardFilteredSearch', () => {
  let wrapper;
  let store;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(BoardFilteredSearch, {
      store,
      propsData: { tokens: [], board: {} },
      provide: {
        boardBaseUrl: 'root',
        isApolloBoard: false,
        initialFilterParams: [],
        ...provide,
      },
    });
  };

  const findFilteredSearch = () => wrapper.findComponent(BoardFilteredSearchCe);

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

  describe('when Apollo boards FF is on', () => {
    let updateTokensSpy;

    beforeEach(async () => {
      createComponent({ provide: { isApolloBoard: true } });

      jest.spyOn(urlUtility, 'updateHistory');
      updateTokensSpy = jest.spyOn(wrapper.vm.$refs.filteredSearch, 'updateTokens');

      wrapper.setProps({
        board: { labels: [{ title: 'test', color: 'black', id: '1' }] },
      });
      await nextTick();
    });

    it('updates url and tokens when board watcher is triggered', () => {
      expect(urlUtility.updateHistory).toHaveBeenCalledWith({
        url: '?label_name[]=test',
      });

      expect(findFilteredSearch().props()).toEqual(
        expect.objectContaining({ eeFilters: { labelName: ['test'] } }),
      );
      expect(updateTokensSpy).toHaveBeenCalled();
    });
  });
});
