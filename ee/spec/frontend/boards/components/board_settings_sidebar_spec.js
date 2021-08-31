import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BoardSettingsListTypes from 'ee_component/boards/components/board_settings_list_types.vue';
import BoardSettingsWipLimit from 'ee_component/boards/components/board_settings_wip_limit.vue';
import { mockLabelList, mockMilestoneList } from 'jest/boards/mock_data';
import BoardSettingsSidebar from '~/boards/components/board_settings_sidebar.vue';
import { LIST } from '~/boards/constants';
import getters from '~/boards/stores/getters';

Vue.use(Vuex);

describe('ee/BoardSettingsSidebar', () => {
  let wrapper;
  let storeActions;

  const createComponent = ({ actions = {}, isWipLimitsOn = false, list = {} }) => {
    storeActions = actions;
    const boardLists = {
      [list.id]: { ...list, maxIssueCount: 0 },
    };

    const store = new Vuex.Store({
      state: { sidebarType: LIST, activeId: list.id, boardLists },
      getters,
      actions: storeActions,
    });

    wrapper = shallowMount(BoardSettingsSidebar, {
      store,
      provide: {
        glFeatures: {
          wipLimits: isWipLimitsOn,
        },
        canAdminList: false,
      },
      stubs: {
        'board-settings-sidebar-wip-limit': BoardSettingsWipLimit,
        'board-settings-list-types': BoardSettingsListTypes,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('confirms we render BoardSettingsSidebarWipLimit', () => {
    createComponent({ list: mockLabelList, isWipLimitsOn: true });

    expect(wrapper.find(BoardSettingsWipLimit).exists()).toBe(true);
  });

  it('confirms we render BoardSettingsListTypes', () => {
    createComponent({ list: mockMilestoneList });

    expect(wrapper.find(BoardSettingsListTypes).exists()).toBe(true);
  });
});
