import { shallowMount } from '@vue/test-utils';
import EpicBoardContentSidebar from 'ee/boards/components/epic_board_content_sidebar.vue';
import BoardContent from '~/boards/components/board_content.vue';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { createStore } from '~/boards/stores';

describe('ee/BoardContent', () => {
  let wrapper;
  let store;

  const createComponent = ({
    issuableType = 'issue',
    isIssueBoard = true,
    isEpicBoard = false,
    isSwimlanesOn = false,
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
        filterParams: {},
        isSwimlanesOn,
      },
      stubs: {
        'board-content-sidebar': BoardContentSidebar,
      },
    });
  };

  beforeEach(() => {
    window.gon = { licensed_features: {} };
    store = createStore();
  });

  describe.each`
    isSwimlanesOn | isIssueBoard | isEpicBoard | resultIssue | resultEpic
    ${true}       | ${true}      | ${false}    | ${true}     | ${false}
    ${false}      | ${true}      | ${false}    | ${true}     | ${false}
    ${false}      | ${false}     | ${true}     | ${false}    | ${true}
  `(
    'with isSwimlanesOn=$isSwimlanesOn',
    ({ isSwimlanesOn, isIssueBoard, isEpicBoard, resultIssue, resultEpic }) => {
      beforeEach(() => {
        createComponent({ isIssueBoard, isEpicBoard, isSwimlanesOn });
      });

      it(`renders BoardContentSidebar = ${resultIssue}`, () => {
        expect(wrapper.findComponent(BoardContentSidebar).exists()).toBe(resultIssue);
      });

      it(`renders EpicBoardContentSidebar = ${resultEpic}`, () => {
        expect(wrapper.findComponent(EpicBoardContentSidebar).exists()).toBe(resultEpic);
      });
    },
  );
});
