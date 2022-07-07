import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import ToggleEpicsSwimlanes from 'ee/boards/components/toggle_epics_swimlanes.vue';
import IssueBoardFilteredSearch from 'ee/boards/components/issue_board_filtered_search.vue';
import EpicBoardFilteredSearch from 'ee/boards/components/epic_filtered_search.vue';
import ToggleLabels from 'ee/boards/components/toggle_labels.vue';

import BoardTopBar from '~/boards/components/board_top_bar.vue';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import ConfigToggle from '~/boards/components/config_toggle.vue';
import NewBoardButton from '~/boards/components/new_board_button.vue';
import ToggleFocus from '~/boards/components/toggle_focus.vue';

describe('BoardTopBar', () => {
  let wrapper;

  Vue.use(Vuex);

  const createStore = ({ mockGetters = {} } = {}) => {
    return new Vuex.Store({
      state: {},
      getters: {
        isEpicBoard: () => false,
        ...mockGetters,
      },
    });
  };

  const createComponent = ({ provide = {}, mockGetters = {} } = {}) => {
    const store = createStore({ mockGetters });
    wrapper = shallowMount(BoardTopBar, {
      store,
      provide: {
        swimlanesFeatureAvailable: false,
        canAdminList: false,
        isSignedIn: false,
        fullPath: 'gitlab-org',
        boardType: 'group',
        releasesFetchPath: '/releases',
        epicFeatureAvailable: true,
        iterationFeatureAvailable: true,
        ...provide,
      },
      stubs: { IssueBoardFilteredSearch, EpicBoardFilteredSearch },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('base template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders BoardsSelector component', () => {
      expect(wrapper.findComponent(BoardsSelector).exists()).toBe(true);
    });

    it('renders NewBoardButton component', () => {
      expect(wrapper.findComponent(NewBoardButton).exists()).toBe(true);
    });

    it('renders ConfigToggle component', () => {
      expect(wrapper.findComponent(ConfigToggle).exists()).toBe(true);
    });

    it('renders ToggleFocus component', () => {
      expect(wrapper.findComponent(ToggleFocus).exists()).toBe(true);
    });

    it('renders ToggleLabels component', () => {
      expect(wrapper.findComponent(ToggleLabels).exists()).toBe(true);
    });

    it('does not render ToggleEpicsSwimlanes component', () => {
      expect(wrapper.findComponent(ToggleEpicsSwimlanes).exists()).toBe(false);
    });
  });

  describe('filter bar', () => {
    it.each`
      isEpicBoard | filterBarComponent          | filterBarName                 | otherFilterBar
      ${false}    | ${IssueBoardFilteredSearch} | ${'IssueBoardFilteredSearch'} | ${EpicBoardFilteredSearch}
      ${true}     | ${EpicBoardFilteredSearch}  | ${'EpicBoardFilteredSearch'}  | ${IssueBoardFilteredSearch}
    `(
      'renders $filterBarName when isEpicBoard is $isEpicBoard',
      async ({ isEpicBoard, filterBarComponent, otherFilterBar }) => {
        createComponent({ mockGetters: { isEpicBoard: () => isEpicBoard } });

        await nextTick();

        expect(wrapper.findComponent(filterBarComponent).exists()).toBe(true);
        expect(wrapper.findComponent(otherFilterBar).exists()).toBe(false);
      },
    );
  });

  describe('when user is logged in and swimlanes are available', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          swimlanesFeatureAvailable: true,
          isSignedIn: true,
        },
      });
    });

    it('renders ToggleEpicsSwimlanes component', () => {
      expect(wrapper.findComponent(ToggleEpicsSwimlanes).exists()).toBe(true);
    });
  });
});
