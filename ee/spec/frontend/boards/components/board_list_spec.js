import { nextTick } from 'vue';

import BoardNewEpic from 'ee/boards/components/board_new_epic.vue';
import createComponent from 'jest/boards/board_list_helper';

import BoardCard from '~/boards/components/board_card.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import BoardCardMoveToPosition from '~/boards/components/board_card_move_to_position.vue';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { TYPE_EPIC, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import listEpicsQuery from 'ee/boards/graphql/lists_epics.query.graphql';
import {
  mockGroupIssuesResponse,
  mockProjectIssuesResponse,
  mockGroupEpicsResponse,
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
  },
};

describe('BoardList Component', () => {
  let wrapper;

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
    const groupIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupIssuesResponse);
    const groupEpicsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupEpicsResponse);

    it.each`
      boardType            | isEpicBoard | queryHandler                        | notCalledHandler
      ${WORKSPACE_GROUP}   | ${false}    | ${groupIssuesQueryHandlerSuccess}   | ${projectIssuesQueryHandlerSuccess}
      ${WORKSPACE_PROJECT} | ${false}    | ${projectIssuesQueryHandlerSuccess} | ${groupIssuesQueryHandlerSuccess}
      ${WORKSPACE_GROUP}   | ${true}     | ${groupEpicsQueryHandlerSuccess}    | ${groupIssuesQueryHandlerSuccess}
    `(
      'fetches $boardType items when isEpicBoard is $isEpicBoard',
      async ({ boardType, isEpicBoard, queryHandler, notCalledHandler }) => {
        createComponent({
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
  });
});
