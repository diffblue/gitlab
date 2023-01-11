import { shallowMount } from '@vue/test-utils';
import EpicBoardContentSidebar from 'ee/boards/components/epic_board_content_sidebar.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { createStore } from '~/boards/stores';

describe('ee/BoardContent', () => {
  let wrapper;
  let store;
  window.gon = { licensed_features: {} };

  const createComponent = ({
    issuableType = 'issue',
    isIssueBoard = true,
    isEpicBoard = false,
  }) => {
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
        isIssueBoard,
        isEpicBoard,
        isGroupBoard: true,
        disabled: false,
        isApolloBoard: false,
      },
      propsData: {
        lists: [],
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
    state                                 | isIssueBoard | isEpicBoard | resultIssue | resultEpic
    ${{ isShowingEpicsSwimlanes: true }}  | ${true}      | ${false}    | ${true}     | ${false}
    ${{ isShowingEpicsSwimlanes: false }} | ${true}      | ${false}    | ${true}     | ${false}
    ${{ isShowingEpicsSwimlanes: false }} | ${false}     | ${true}     | ${false}    | ${true}
  `('with state=$state', ({ state, isIssueBoard, isEpicBoard, resultIssue, resultEpic }) => {
    beforeEach(() => {
      Object.assign(store.state, state);
      createComponent({ isIssueBoard, isEpicBoard });
    });

    it(`renders BoardContentSidebar = ${resultIssue}`, () => {
      expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(resultIssue);
    });

    it(`renders EpicBoardContentSidebar = ${resultEpic}`, () => {
      expect(wrapper.findComponent(EpicBoardContentSidebar).exists()).toBe(resultEpic);
    });
  });
});
