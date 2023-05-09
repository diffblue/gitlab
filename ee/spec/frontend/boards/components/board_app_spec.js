import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { issueBoardListsQueryResponse } from 'jest/boards/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import BoardApp from '~/boards/components/board_app.vue';
import epicBoardListsQuery from 'ee_component/boards/graphql/epic_board_lists.query.graphql';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import { rawIssue, epicBoardListsQueryResponse } from '../mock_data';

describe('BoardApp', () => {
  const boardListQueryHandler = jest.fn().mockResolvedValue(issueBoardListsQueryResponse);
  const epicBoardListQueryHandler = jest.fn().mockResolvedValue(epicBoardListsQueryResponse);
  const mockApollo = createMockApollo([
    [boardListsQuery, boardListQueryHandler],
    [epicBoardListsQuery, epicBoardListQueryHandler],
  ]);

  Vue.use(VueApollo);

  const createComponent = ({ issue = rawIssue, provide = {} } = {}) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: issue,
      },
    });

    shallowMount(BoardApp, {
      apolloProvider: mockApollo,
      provide: {
        fullPath: 'gitlab-org',
        initialBoardId: 'gid://gitlab/Board/1',
        initialFilterParams: {},
        issuableType: 'issue',
        boardType: 'group',
        isIssueBoard: true,
        isGroupBoard: true,
        isApolloBoard: true,
        ...provide,
      },
    });
  };

  it.each`
    issuableType | isIssueBoard | isEpicBoard | queryHandler                 | notCalledHandler
    ${'epic'}    | ${false}     | ${true}     | ${epicBoardListQueryHandler} | ${boardListQueryHandler}
    ${'issue'}   | ${true}      | ${false}    | ${boardListQueryHandler}     | ${epicBoardListQueryHandler}
  `(
    'fetches $issuableType lists',
    ({ issuableType, isIssueBoard, isEpicBoard, queryHandler, notCalledHandler }) => {
      createComponent({
        provide: { isApolloBoard: true, issuableType, isEpicBoard, isIssueBoard },
      });

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    },
  );
});
