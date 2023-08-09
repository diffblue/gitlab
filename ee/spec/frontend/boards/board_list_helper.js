import Vue from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardCard from '~/boards/components/board_card.vue';
import BoardList from '~/boards/components/board_list.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import defaultState from '~/boards/stores/state';
import createMockApollo from 'helpers/mock_apollo_helper';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import listEpicsQuery from 'ee/boards/graphql/lists_epics.query.graphql';
import epicListDeferredQuery from 'ee/boards/graphql/epic_board_lists_deferred.query.graphql';
import {
  mockList,
  mockGroupProjects,
  boardListQueryResponse,
  epicBoardListQueryResponse,
} from 'jest/boards/mock_data';
import {
  mockIssuesByListId,
  issues,
  mockGroupIssuesResponse,
  mockGroupEpicsResponse,
  rawIssue,
} from './mock_data';

export default function createComponent({
  listIssueProps = {},
  componentProps = {},
  listProps = {},
  apolloQueryHandlers = [],
  actions = {},
  getters = {},
  provide = {},
  data = {},
  state = defaultState,
  stubs = {
    BoardNewIssue,
    BoardNewItem,
    BoardCard,
  },
  issuesCount,
} = {}) {
  Vue.use(VueApollo);
  Vue.use(Vuex);

  const fakeApollo = createMockApollo([
    [listQuery, jest.fn().mockResolvedValue(boardListQueryResponse({ issuesCount }))],
    ...apolloQueryHandlers,
  ]);

  const baseListQueryVariables = {
    fullPath: 'gitlab-org',
    boardId: 'gid://gitlab/Board/1',
    filters: {},
    isGroup: true,
    isProject: false,
    first: 10,
  };

  fakeApollo.clients.defaultClient.writeQuery({
    query: listQuery,
    variables: { id: 'gid://gitlab/List/1', filters: {} },
    data: boardListQueryResponse({ listId: 'gid://gitlab/List/1' }).data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: listQuery,
    variables: { id: 'gid://gitlab/List/2', filters: {} },
    data: boardListQueryResponse({ listId: 'gid://gitlab/List/2' }).data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: listIssuesQuery,
    variables: { ...baseListQueryVariables, id: 'gid://gitlab/List/1' },
    data: mockGroupIssuesResponse('gid://gitlab/List/1', [
      { ...rawIssue, id: 'gid://gitlab/Issue/437' },
    ]).data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: listIssuesQuery,
    variables: { ...baseListQueryVariables, id: 'gid://gitlab/List/2' },
    data: mockGroupIssuesResponse('gid://gitlab/List/2', [{ ...rawIssue, iid: '28' }]).data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: epicListDeferredQuery,
    variables: { id: 'gid://gitlab/Boards::EpicList/4', filters: {} },
    data: epicBoardListQueryResponse().data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: epicListDeferredQuery,
    variables: { id: 'gid://gitlab/Boards::EpicList/5', filters: {} },
    data: epicBoardListQueryResponse().data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: listEpicsQuery,
    variables: { ...baseListQueryVariables, id: 'gid://gitlab/Boards::EpicList/4' },
    data: mockGroupEpicsResponse.data,
  });
  fakeApollo.clients.defaultClient.writeQuery({
    query: listEpicsQuery,
    variables: { ...baseListQueryVariables, id: 'gid://gitlab/Boards::EpicList/5' },
    data: mockGroupEpicsResponse.data,
  });

  const store = new Vuex.Store({
    state: {
      selectedProject: mockGroupProjects[0],
      boardItemsByListId: mockIssuesByListId,
      boardItems: issues,
      pageInfoByListId: {
        'gid://gitlab/List/1': { hasNextPage: true },
        'gid://gitlab/List/2': {},
      },
      listsFlags: {
        'gid://gitlab/List/1': {},
        'gid://gitlab/List/2': {},
      },
      selectedBoardItems: [],
      ...state,
    },
    getters: {
      isEpicBoard: () => false,
      ...getters,
    },
    actions,
  });

  const list = {
    ...mockList,
    ...listProps,
  };
  const issue = {
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    referencePath: 'gitlab-org/test-subgroup/gitlab-test#1',
    labels: [],
    assignees: [],
    ...listIssueProps,
  };
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesCount')) {
    list.issuesCount = 1;
  }

  const component = shallowMountExtended(BoardList, {
    apolloProvider: fakeApollo,
    store,
    propsData: {
      list,
      boardItems: [issue],
      canAdminList: true,
      boardId: 'gid://gitlab/Board/1',
      filterParams: {},
      ...componentProps,
    },
    provide: {
      groupId: null,
      rootPath: '/',
      fullPath: 'gitlab-org',
      boardId: '1',
      weightFeatureAvailable: false,
      boardWeight: null,
      canAdminList: true,
      isIssueBoard: true,
      isEpicBoard: false,
      isGroupBoard: false,
      isProjectBoard: true,
      disabled: false,
      boardType: 'group',
      issuableType: 'issue',
      isApolloBoard: false,
      ...provide,
    },
    stubs,
    data() {
      return {
        ...data,
      };
    },
  });

  return component;
}
