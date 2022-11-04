import { shallowMount } from '@vue/test-utils';
import EpicBoardContentSidebar from 'ee/boards/components/epic_board_content_sidebar.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { createStore } from '~/boards/stores';

describe('ee/BoardContent', () => {
  let wrapper;
  let store;
  window.gon = { licensed_features: {} };

  const createComponent = ({ issuableType = 'issue' }) => {
    wrapper = shallowMount(BoardContent, {
      store,
      provide: {
        timeTrackingLimitToHours: false,
        canAdminList: false,
        canUpdate: false,
        labelsFilterBasePath: '',
        boardType: 'group',
        fullPath: 'gitlab-org/gitlab',
        issuableType,
        isApolloBoard: false,
      },
      propsData: {
        lists: [],
        disabled: false,
        boardId: 'gid://gitlab/Board/1',
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
    state                                 | issuableType | resultIssue | resultEpic
    ${{ isShowingEpicsSwimlanes: true }}  | ${'issue'}   | ${true}     | ${false}
    ${{ isShowingEpicsSwimlanes: false }} | ${'issue'}   | ${true}     | ${false}
    ${{ isShowingEpicsSwimlanes: false }} | ${'epic'}    | ${false}    | ${true}
  `('with state=$state', ({ state, issuableType, resultIssue, resultEpic }) => {
    beforeEach(() => {
      Object.assign(store.state, state);
      createComponent({ issuableType });
    });

    it(`renders BoardContentSidebar = ${resultIssue}`, () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(resultIssue);
    });

    it(`renders EpicBoardContentSidebar = ${resultEpic}`, () => {
      expect(wrapper.findComponent(EpicBoardContentSidebar).exists()).toBe(resultEpic);
    });
  });
});
