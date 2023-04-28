import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import BoardSettingsListTypes from 'ee_component/boards/components/board_settings_list_types.vue';
import BoardSettingsWipLimit from 'ee_component/boards/components/board_settings_wip_limit.vue';
import epicBoardListsQuery from 'ee_component/boards/graphql/epic_board_lists.query.graphql';
import {
  mockLabelList,
  mockMilestoneList,
  issueBoardListsQueryResponse,
} from 'jest/boards/mock_data';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import { LIST } from '~/boards/constants';
import getters from '~/boards/stores/getters';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import { epicBoardListsQueryResponse } from '../mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('ee/BoardSettingsSidebar', () => {
  let wrapper;
  let mockApollo;
  let storeActions;

  const boardListQueryHandler = jest.fn().mockResolvedValue(issueBoardListsQueryResponse);
  const epicBoardListQueryHandler = jest.fn().mockResolvedValue(epicBoardListsQueryResponse);

  const createComponent = ({
    actions = {},
    isWipLimitsOn = false,
    list = {},
    provide = {},
  } = {}) => {
    storeActions = actions;
    const boardLists = {
      [list.id]: { ...list, maxIssueCount: 0 },
    };

    const store = new Vuex.Store({
      state: { sidebarType: LIST, activeId: list.id, boardLists },
      getters,
      actions: storeActions,
    });

    mockApollo = createMockApollo([
      [boardListsQuery, boardListQueryHandler],
      [epicBoardListsQuery, epicBoardListQueryHandler],
    ]);

    wrapper = shallowMount(BoardSettingsSidebar, {
      apolloProvider: mockApollo,
      store,
      provide: {
        glFeatures: {
          wipLimits: isWipLimitsOn,
        },
        canAdminList: false,
        scopedLabelsAvailable: true,
        isIssueBoard: true,
        boardType: 'group',
        fullPath: 'gitlab-org',
        issuableType: 'issue',
        isGroupBoard: true,
        isApolloBoard: false,
        ...provide,
      },
      propsData: {
        listId: 'gid://gitlab/List/1',
        boardId: 'gid://gitlab/Board/1',
      },
      stubs: {
        'board-settings-sidebar-wip-limit': BoardSettingsWipLimit,
        'board-settings-list-types': BoardSettingsListTypes,
      },
    });
  };

  it('confirms we render BoardSettingsSidebarWipLimit', () => {
    createComponent({ list: mockLabelList, isWipLimitsOn: true });

    expect(wrapper.findComponent(BoardSettingsWipLimit).exists()).toBe(true);
  });

  it('confirms we render BoardSettingsListTypes', () => {
    createComponent({ list: mockMilestoneList });

    expect(wrapper.findComponent(BoardSettingsListTypes).exists()).toBe(true);
  });

  it('passes scoped prop to label when label is scoped', () => {
    createComponent({
      list: { ...mockLabelList, label: { ...mockLabelList.label, title: 'foo::bar' } },
    });

    expect(wrapper.findComponent(GlLabel).props('scoped')).toBe(true);
  });

  describe('Apollo boards', () => {
    it.each`
      issuableType | isIssueBoard | isEpicBoard | queryHandler                 | notCalledHandler
      ${'epic'}    | ${false}     | ${true}     | ${epicBoardListQueryHandler} | ${boardListQueryHandler}
      ${'issue'}   | ${true}      | ${false}    | ${boardListQueryHandler}     | ${epicBoardListQueryHandler}
    `(
      'fetches $issuableType list info',
      ({ issuableType, isIssueBoard, isEpicBoard, queryHandler, notCalledHandler }) => {
        createComponent({
          provide: { isApolloBoard: true, issuableType, isEpicBoard, isIssueBoard },
        });

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );
  });
});
