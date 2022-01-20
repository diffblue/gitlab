import { shallowMount } from '@vue/test-utils';
import EpicBoardContentSidebar from 'ee/boards/components/epic_board_content_sidebar.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { createStore } from '~/boards/stores';

describe('ee/BoardContent', () => {
  let wrapper;
  let store;
  window.gon = { licensed_features: {} };

  const createComponent = () => {
    wrapper = shallowMount(BoardContent, {
      store,
      provide: {
        timeTrackingLimitToHours: false,
        canAdminList: false,
        canUpdate: false,
        labelsFilterBasePath: '',
      },
      propsData: {
        lists: [],
        disabled: false,
      },
      stubs: {
        'board-content-sidebar': BoardContentSidebar,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    window.gon.licensed_features = {};
    wrapper.destroy();
  });

  describe.each`
    state                                                        | resultIssue | resultEpic
    ${{ isShowingEpicsSwimlanes: true, issuableType: 'issue' }}  | ${true}     | ${false}
    ${{ isShowingEpicsSwimlanes: false, issuableType: 'issue' }} | ${true}     | ${false}
    ${{ isShowingEpicsSwimlanes: false, issuableType: 'epic' }}  | ${false}    | ${true}
  `('with state=$state', ({ state, resultIssue, resultEpic }) => {
    beforeEach(() => {
      Object.assign(store.state, state);
      createComponent();
    });

    it(`renders BoardContentSidebar = ${resultIssue}`, () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(resultIssue);
    });

    it(`renders EpicBoardContentSidebar = ${resultEpic}`, () => {
      expect(wrapper.findComponent(EpicBoardContentSidebar).exists()).toBe(resultEpic);
    });
  });
});
