import { nextTick } from 'vue';
import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import waitForPromises from 'helpers/wait_for_promises';

import { DraggableItemTypes } from 'ee_else_ce/boards/constants';
import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import issueCreateMutation from '~/boards/graphql/issue_create.mutation.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { TYPE_EPIC, TYPE_ISSUE, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import eventHub from '~/boards/eventhub';
import issueMoveListMutation from 'ee/boards/graphql/issue_move_list.mutation.graphql';
import epicMoveListMutation from 'ee/boards/graphql/epic_move_list.mutation.graphql';
import epicCreateMutation from 'ee/boards/graphql/epic_create.mutation.graphql';
import listEpicsQuery from 'ee/boards/graphql/lists_epics.query.graphql';
import { mockList } from 'jest/boards/mock_data';
import createComponent from '../board_list_helper';
import {
  mockGroupIssuesResponse,
  mockProjectIssuesResponse,
  mockGroupEpicsResponse,
  moveIssueMutationResponse,
  moveEpicMutationResponse,
  mockIssues,
  mockEpics,
  createIssueMutationResponse,
  createEpicMutationResponse,
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

beforeEach(() => {
  cacheUpdates.setError = jest.fn();
});

describe('BoardList Component', () => {
  let wrapper;

  const endDrag = (params) => {
    wrapper.findByTestId('tree-root-wrapper').vm.$emit('end', params);
  };
  const findNewIssueForm = () => wrapper.findComponent(BoardNewIssue);
  const findNewEpicForm = () => wrapper.findComponent(BoardNewEpic);

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

  it('does not render new item form by default', () => {
    expect(findNewIssueForm().exists()).toBe(false);
    expect(findNewEpicForm().exists()).toBe(false);
  });

  it.each`
    issuableType  | isEpicBoard | formComponent    | notRenderedFormComponent
    ${TYPE_EPIC}  | ${true}     | ${BoardNewEpic}  | ${BoardNewIssue}
    ${TYPE_ISSUE} | ${false}    | ${BoardNewIssue} | ${BoardNewEpic}
  `(
    'renders $issuableType form on adding new item',
    async ({ issuableType, isEpicBoard, formComponent, notRenderedFormComponent }) => {
      wrapper = createComponent({
        provide: {
          issuableType,
          isProjectBoard: false,
          isGroupBoard: true,
          isEpicBoard,
        },
        stubs: {
          BoardNewIssue,
          BoardNewEpic,
        },
      });

      await waitForPromises();

      eventHub.$emit(`toggle-${issuableType}-form-${mockList.id}`);

      await nextTick();
      expect(wrapper.findComponent(formComponent).exists()).toBe(true);
      expect(wrapper.findComponent(notRenderedFormComponent).exists()).toBe(false);
    },
  );

  describe('Apollo boards', () => {
    const projectIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectIssuesResponse);
    const groupIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupIssuesResponse());
    const groupEpicsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupEpicsResponse);
    const moveIssueMutationHandlerSuccess = jest.fn().mockResolvedValue(moveIssueMutationResponse);
    const moveEpicMutationHandlerSuccess = jest.fn().mockResolvedValue(moveEpicMutationResponse);
    const createIssueMutationHandlerSuccess = jest
      .fn()
      .mockResolvedValue(createIssueMutationResponse);
    const createEpicMutationHandlerSuccess = jest
      .fn()
      .mockResolvedValue(createEpicMutationResponse);
    const queryHandlerFailure = jest.fn().mockRejectedValue(new Error('error'));

    const apolloQueryHandlers = [
      [listIssuesQuery, groupIssuesQueryHandlerSuccess],
      [listEpicsQuery, groupEpicsQueryHandlerSuccess],
      [issueMoveListMutation, moveIssueMutationHandlerSuccess],
      [epicMoveListMutation, moveEpicMutationHandlerSuccess],
      [issueCreateMutation, createIssueMutationHandlerSuccess],
      [epicCreateMutation, createEpicMutationHandlerSuccess],
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
      boardType            | isEpicBoard
      ${WORKSPACE_GROUP}   | ${false}
      ${WORKSPACE_PROJECT} | ${false}
      ${WORKSPACE_GROUP}   | ${true}
    `(
      'set error when fetch $boardType items fails when isEpicBoard is $isEpicBoard',
      async ({ boardType, isEpicBoard }) => {
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
            [listIssuesQuery, queryHandlerFailure],
            [listEpicsQuery, queryHandlerFailure],
          ],
        });

        await waitForPromises();

        expect(cacheUpdates.setError).toHaveBeenCalled();
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
      issuableType  | isEpicBoard | endDragVariables
      ${TYPE_ISSUE} | ${false}    | ${endDragIssueVariables}
      ${TYPE_EPIC}  | ${true}     | ${endDragEpicVariables}
    `(
      'sets error when moving $issuableType between lists fails',
      async ({ issuableType, isEpicBoard, endDragVariables }) => {
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
          apolloQueryHandlers: [
            [listIssuesQuery, groupIssuesQueryHandlerSuccess],
            [listEpicsQuery, groupEpicsQueryHandlerSuccess],
            [issueMoveListMutation, queryHandlerFailure],
            [epicMoveListMutation, queryHandlerFailure],
          ],
        });

        await waitForPromises();

        endDrag(endDragVariables);

        await waitForPromises();

        expect(cacheUpdates.setError).toHaveBeenCalled();
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

    it.each`
      issuableType  | isEpicBoard | positionInList
      ${TYPE_ISSUE} | ${false}    | ${-1}
      ${TYPE_EPIC}  | ${true}     | ${-1}
    `(
      'sets error when moving $issuableType at bottom of list fails',
      async ({ issuableType, isEpicBoard, positionInList }) => {
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
          apolloQueryHandlers: [
            [listIssuesQuery, groupIssuesQueryHandlerSuccess],
            [listEpicsQuery, groupEpicsQueryHandlerSuccess],
            [issueMoveListMutation, queryHandlerFailure],
            [epicMoveListMutation, queryHandlerFailure],
          ],
        });

        await waitForPromises();

        wrapper.findComponent(BoardCardMoveToPosition).vm.$emit('moveToPosition', positionInList);

        await waitForPromises();

        expect(cacheUpdates.setError).toHaveBeenCalled();
      },
    );

    it.each`
      issuableType  | isEpicBoard | queryHandler                         | notCalledHandler                     | component        | event            | listId
      ${TYPE_ISSUE} | ${false}    | ${createIssueMutationHandlerSuccess} | ${createEpicMutationHandlerSuccess}  | ${BoardNewIssue} | ${'addNewIssue'} | ${mockList.id}
      ${TYPE_EPIC}  | ${true}     | ${createEpicMutationHandlerSuccess}  | ${createIssueMutationHandlerSuccess} | ${BoardNewEpic}  | ${'addNewEpic'}  | ${'gid://gitlab/Boards::EpicList/5'}
    `(
      'creates $issuableType',
      async ({
        issuableType,
        isEpicBoard,
        queryHandler,
        notCalledHandler,
        component,
        event,
        listId,
      }) => {
        wrapper = createComponent({
          listProps: {
            id: listId,
          },
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
            BoardNewIssue,
            BoardNewEpic,
          },
        });

        await waitForPromises();

        eventHub.$emit(`toggle-${issuableType}-form-${listId}`);
        await nextTick();
        expect(wrapper.findComponent(component).exists()).toBe(true);
        wrapper.findComponent(component).vm.$emit(event, { title: 'Foo' });

        await nextTick();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );

    it.each`
      issuableType  | isEpicBoard | component        | event            | listId
      ${TYPE_ISSUE} | ${false}    | ${BoardNewIssue} | ${'addNewIssue'} | ${mockList.id}
      ${TYPE_EPIC}  | ${true}     | ${BoardNewEpic}  | ${'addNewEpic'}  | ${'gid://gitlab/Boards::EpicList/5'}
    `(
      'sets error when creating $issuableType fails',
      async ({ issuableType, isEpicBoard, component, event, listId }) => {
        wrapper = createComponent({
          listProps: {
            id: listId,
          },
          provide: {
            boardType: WORKSPACE_GROUP,
            issuableType,
            isProjectBoard: false,
            isGroupBoard: true,
            isEpicBoard,
            isApolloBoard: true,
            glFeatures: { epicColorHighlight: false },
          },
          apolloQueryHandlers: [
            [listIssuesQuery, groupIssuesQueryHandlerSuccess],
            [listEpicsQuery, groupEpicsQueryHandlerSuccess],
            [issueCreateMutation, queryHandlerFailure],
            [epicCreateMutation, queryHandlerFailure],
          ],
          stubs: {
            BoardNewIssue,
            BoardNewEpic,
          },
        });

        await waitForPromises();

        eventHub.$emit(`toggle-${issuableType}-form-${listId}`);
        await nextTick();
        expect(wrapper.findComponent(component).exists()).toBe(true);
        wrapper.findComponent(component).vm.$emit(event, { title: 'Foo' });

        await waitForPromises();

        expect(cacheUpdates.setError).toHaveBeenCalled();
      },
    );
  });
});
