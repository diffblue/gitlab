import { nextTick } from 'vue';
import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import waitForPromises from 'helpers/wait_for_promises';

import { DraggableItemTypes } from 'ee_else_ce/boards/constants';
import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { TYPE_EPIC, TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import issueMoveListMutation from 'ee/boards/graphql/issue_move_list.mutation.graphql';
import epicMoveListMutation from 'ee/boards/graphql/epic_move_list.mutation.graphql';
import listEpicsQuery from 'ee/boards/graphql/lists_epics.query.graphql';
import createComponent from '../board_list_helper';
import {
  mockGroupIssuesResponse,
  mockProjectIssuesResponse,
  mockGroupEpicsResponse,
  moveIssueMutationResponse,
  moveEpicMutationResponse,
  mockIssues,
  mockEpics,
} from '../mock_data';

jest.mock('~/alert');

const actions = {
  addListNewEpic: jest.fn().mockResolvedValue(),
};

const componentConfig = {
  actions,
  stubs: {
    BoardCard,
    BoardCardInner,
    BoardNewEpic,
    BoardCardMoveToPosition,
  },
  provide: {
    scopedLabelsAvailable: true,
    isEpicBoard: true,
    issuableType: TYPE_EPIC,
    isGroupBoard: true,
    isProjectBoard: false,
    isApolloBoard: false,
  },
};

describe('BoardList Component', () => {
  let wrapper;

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const endDrag = (params) => {
    findByTestId('tree-root-wrapper').vm.$emit('end', params);
  };

  beforeEach(() => {
    wrapper = createComponent(componentConfig);
  });

  it('renders link properly in issue', () => {
    expect(wrapper.find('.board-card .board-card-title a').attributes('href')).not.toContain(
      ':project_path',
    );
  });

  it('renders the move to position icon', () => {
    expect(wrapper.findComponent(BoardCardMoveToPosition).exists()).toBe(true);
  });

  describe('Apollo boards', () => {
    const projectIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectIssuesResponse);
    const groupIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupIssuesResponse());
    const groupEpicsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupEpicsResponse);
    const moveIssueMutationHandlerSuccess = jest.fn().mockResolvedValue(moveIssueMutationResponse);
    const moveEpicMutationHandlerSuccess = jest.fn().mockResolvedValue(moveEpicMutationResponse);

    const apolloQueryHandlers = [
      [listIssuesQuery, groupIssuesQueryHandlerSuccess],
      [listEpicsQuery, groupEpicsQueryHandlerSuccess],
      [issueMoveListMutation, moveIssueMutationHandlerSuccess],
      [epicMoveListMutation, moveEpicMutationHandlerSuccess],
    ];

    const endDragIssueVariables = {
      oldIndex: 1,
      newIndex: 0,
      item: {
        dataset: {
          draggableItemType: DraggableItemTypes.card,
          itemId: mockIssues[0].id,
          itemIid: mockIssues[0].iid,
          itemPath: mockIssues[0].referencePath,
        },
      },
      to: { children: [], dataset: { listId: 'gid://gitlab/List/2' } },
      from: { dataset: { listId: 'gid://gitlab/List/1' } },
    };
    const endDragEpicVariables = {
      oldIndex: 1,
      newIndex: 0,
      item: {
        dataset: {
          draggableItemType: DraggableItemTypes.card,
          itemId: mockEpics[1].id,
          itemIid: mockEpics[1].iid,
          itemPath: mockEpics[1].referencePath,
        },
      },
      to: { children: [], dataset: { listId: 'gid://gitlab/Boards::EpicList/5' } },
      from: { dataset: { listId: 'gid://gitlab/Boards::EpicList/4' } },
    };

    it.each`
      boardType            | isEpicBoard | queryHandler                        | notCalledHandler
      ${WORKSPACE_GROUP}   | ${false}    | ${groupIssuesQueryHandlerSuccess}   | ${projectIssuesQueryHandlerSuccess}
      ${WORKSPACE_PROJECT} | ${false}    | ${projectIssuesQueryHandlerSuccess} | ${groupIssuesQueryHandlerSuccess}
      ${WORKSPACE_GROUP}   | ${true}     | ${groupEpicsQueryHandlerSuccess}    | ${groupIssuesQueryHandlerSuccess}
    `(
      'fetches $boardType items when isEpicBoard is $isEpicBoard',
      async ({ boardType, isEpicBoard, queryHandler, notCalledHandler }) => {
        createComponent({
          listProps: {
            id: 'gid://gitlab/List/3',
          },
          provide: {
            boardType,
            issuableType: isEpicBoard ? 'epic' : 'issue',
            isProjectBoard: boardType === WORKSPACE_PROJECT,
            isGroupBoard: boardType === WORKSPACE_GROUP,
            isEpicBoard,
            isApolloBoard: true,
          },
          apolloQueryHandlers: [
            [listIssuesQuery, queryHandler],
            [listEpicsQuery, groupEpicsQueryHandlerSuccess],
          ],
          stubs: {
            BoardCardMoveToPosition,
          },
        });

        await nextTick();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );

    it.each`
      issuableType  | isEpicBoard | endDragVariables         | queryHandler                       | notCalledHandler
      ${TYPE_ISSUE} | ${false}    | ${endDragIssueVariables} | ${moveIssueMutationHandlerSuccess} | ${moveEpicMutationHandlerSuccess}
      ${TYPE_EPIC}  | ${true}     | ${endDragEpicVariables}  | ${moveEpicMutationHandlerSuccess}  | ${moveIssueMutationHandlerSuccess}
    `(
      'moves $issuableType between lists',
      async ({ issuableType, isEpicBoard, queryHandler, notCalledHandler, endDragVariables }) => {
        wrapper = createComponent({
          provide: {
            boardType: WORKSPACE_GROUP,
            issuableType,
            isProjectBoard: false,
            isGroupBoard: true,
            isEpicBoard,
            isApolloBoard: true,
            glFeatures: { epicColorHighlight: false },
          },
          apolloQueryHandlers,
          stubs: {
            BoardCardMoveToPosition,
          },
        });

        await waitForPromises();

        endDrag(endDragVariables);

        await waitForPromises();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );

    it.each`
      issuableType  | isEpicBoard | positionInList | queryHandler                       | notCalledHandler
      ${TYPE_ISSUE} | ${false}    | ${-1}          | ${moveIssueMutationHandlerSuccess} | ${moveEpicMutationHandlerSuccess}
      ${TYPE_EPIC}  | ${true}     | ${-1}          | ${moveEpicMutationHandlerSuccess}  | ${moveIssueMutationHandlerSuccess}
    `(
      'moves $issuableType at bottom of list',
      async ({ issuableType, isEpicBoard, queryHandler, notCalledHandler, positionInList }) => {
        wrapper = createComponent({
          provide: {
            boardType: WORKSPACE_GROUP,
            issuableType,
            isProjectBoard: false,
            isGroupBoard: true,
            isEpicBoard,
            isApolloBoard: true,
            glFeatures: { epicColorHighlight: false },
          },
          apolloQueryHandlers,
        });

        await waitForPromises();

        wrapper.findComponent(BoardCardMoveToPosition).vm.$emit('moveToPosition', positionInList);

        await waitForPromises();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );
  });
});
