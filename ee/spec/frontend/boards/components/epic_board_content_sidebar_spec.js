import { GlDrawer } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { MountingPortal } from 'portal-vue';
import Vue from 'vue';
import Vuex from 'vuex';
import EpicBoardContentSidebar from 'ee_component/boards/components/epic_board_content_sidebar.vue';
import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';
import { stubComponent } from 'helpers/stub_component';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import { ISSUABLE, issuableTypes } from '~/boards/constants';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarDateWidget from '~/sidebar/components/date/sidebar_date_widget.vue';
import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import LabelsSelectWidget from '~/sidebar/components/labels/labels_select_widget/labels_select_root.vue';
import ColorSelectDropdown from '~/vue_shared/components/color_select_dropdown/color_select_root.vue';
import { mockFormattedBoardEpic } from '../mock_data';

Vue.use(Vuex);

describe('EpicBoardContentSidebar', () => {
  let wrapper;
  let store;

  const createStore = ({ mockGetters = {}, mockActions = {} } = {}) => {
    store = new Vuex.Store({
      state: {
        sidebarType: ISSUABLE,
        boardItems: { [mockFormattedBoardEpic.id]: mockFormattedBoardEpic },
        activeId: mockFormattedBoardEpic.id,
        fullPath: 'gitlab-org',
      },
      getters: {
        activeBoardItem: () => {
          return mockFormattedBoardEpic;
        },
        isSidebarOpen: () => true,
        ...mockGetters,
      },
      actions: mockActions,
    });
  };

  const createComponent = ({ glFeatures = {} } = {}) => {
    wrapper = shallowMount(EpicBoardContentSidebar, {
      provide: {
        canUpdate: true,
        rootPath: '/',
        groupId: 1,
        issuableType: issuableTypes.epic,
        labelsFilterBasePath: '',
        glFeatures,
      },
      store,
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: '<div><slot name="header"></slot><slot></slot></div>',
        }),
      },
    });
  };

  beforeEach(() => {
    createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('confirms we render GlDrawer', () => {
    expect(wrapper.findComponent(GlDrawer).exists()).toBe(true);
  });

  it('confirms we render MountingPortal', () => {
    expect(wrapper.findComponent(MountingPortal).props()).toMatchObject({
      mountTo: '#js-right-sidebar-portal',
      append: true,
      name: 'epic-board-sidebar',
    });
  });

  it('does not render GlDrawer when isSidebarOpen is false', () => {
    createStore({ mockGetters: { isSidebarOpen: () => false } });
    createComponent();

    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(false);
  });

  it('applies an open attribute', () => {
    expect(wrapper.findComponent(GlDrawer).props('open')).toBe(true);
  });

  it('renders SidebarTodoWidget passing correct epic fullPath', () => {
    expect(wrapper.findComponent(SidebarTodoWidget).exists()).toBe(true);
    expect(wrapper.findComponent(SidebarTodoWidget).props('fullPath')).toBe(
      'gitlab-org/gitlab-subgroup',
    );
  });

  it('renders LabelsSelectWidget', () => {
    expect(wrapper.findComponent(LabelsSelectWidget).exists()).toBe(true);
  });

  it('renders ColorDropdownSelect when epic_color_highlight is enabled', () => {
    createComponent({
      glFeatures: {
        epicColorHighlight: true,
      },
    });
    expect(wrapper.findComponent(ColorSelectDropdown).exists()).toBe(true);
  });

  it('does not render ColorDropdownSelect when epic_color_highlight is disabled', () => {
    expect(wrapper.findComponent(ColorSelectDropdown).exists()).toBe(false);
  });

  it('renders BoardSidebarTitle', () => {
    expect(wrapper.findComponent(BoardSidebarTitle).exists()).toBe(true);
  });

  it('renders SidebarConfidentialityWidget', () => {
    expect(wrapper.findComponent(SidebarConfidentialityWidget).exists()).toBe(true);
  });

  it('renders 2 SidebarDateWidget', () => {
    expect(wrapper.findAllComponents(SidebarDateWidget)).toHaveLength(2);
  });

  it('renders SidebarParticipantsWidget', () => {
    expect(wrapper.findComponent(SidebarParticipantsWidget).exists()).toBe(true);
  });

  it('renders SidebarSubscriptionsWidget', () => {
    expect(wrapper.findComponent(SidebarSubscriptionsWidget).exists()).toBe(true);
  });
  it('renders SidebarAncestorsWidget', () => {
    expect(wrapper.findComponent(SidebarAncestorsWidget).exists()).toBe(true);
  });

  describe('when we emit close', () => {
    let toggleBoardItem;

    beforeEach(() => {
      toggleBoardItem = jest.fn();
      createStore({ mockActions: { toggleBoardItem } });
      createComponent();
    });

    it('calls toggleBoardItem with correct parameters', async () => {
      wrapper.findComponent(GlDrawer).vm.$emit('close');

      expect(toggleBoardItem).toHaveBeenCalledTimes(1);
      expect(toggleBoardItem).toHaveBeenCalledWith(expect.any(Object), {
        boardItem: mockFormattedBoardEpic,
        sidebarType: ISSUABLE,
      });
    });
  });
});
