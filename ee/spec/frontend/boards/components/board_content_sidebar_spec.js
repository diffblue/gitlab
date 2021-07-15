import { GlDrawer } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { stubComponent } from 'helpers/stub_component';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { ISSUABLE, issuableTypes } from '~/boards/constants';
import { mockIssue, mockIssueGroupPath, mockIssueProjectPath } from '../mock_data';

describe('ee/BoardContentSidebar', () => {
  let wrapper;
  let store;

  const createStore = ({ mockGetters = {}, mockActions = {} } = {}) => {
    store = new Vuex.Store({
      state: {
        sidebarType: ISSUABLE,
        issues: { [mockIssue.id]: { ...mockIssue, epic: null } },
        activeId: mockIssue.id,
        issuableType: issuableTypes.issue,
      },
      getters: {
        activeBoardItem: () => {
          return { ...mockIssue, epic: null };
        },
        projectPathForActiveIssue: () => mockIssueProjectPath,
        groupPathForActiveIssue: () => mockIssueGroupPath,
        isSidebarOpen: () => true,
        ...mockGetters,
      },
      actions: mockActions,
    });
  };

  const setPortalAnchorPoint = () => {
    const el = document.createElement('div');
    el.setAttribute('id', 'js-right-sidebar-portal');
    document.body.appendChild(el);
  };

  const createComponent = () => {
    setPortalAnchorPoint();

    /*
      Dynamically imported components (in our case ee imports)
      aren't stubbed automatically when using shallow mount in VTU v1:
      https://github.com/vuejs/vue-test-utils/issues/1279.

      This requires us to use mount and additionally mock components.
    */
    wrapper = mount(BoardContentSidebar, {
      provide: {
        canUpdate: true,
        rootPath: '/',
        groupId: 1,
        epicFeatureAvailable: true,
        iterationFeatureAvailable: true,
        weightFeatureAvailable: true,
      },
      store,
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: `
            <div>
              <slot name="title"></slot>
              <slot name="header"></slot>
              <slot></slot>
            </div>`,
        }),
        BoardEditableItem: true,
        BoardSidebarTitle: true,
        BoardSidebarTimeTracker: true,
        BoardSidebarLabelsSelect: true,
        SidebarAssigneesWidget: true,
        SidebarConfidentialityWidget: true,
        SidebarDateWidget: true,
        SidebarSubscriptionsWidget: true,
        SidebarWeightWidget: true,
        SidebarDropdownWidget: true,
        SidebarTodoWidget: true,
        MountingPortal: true,
      },
    });
  };

  beforeEach(() => {
    createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches the snapshot', () => {
    expect(wrapper.find(GlDrawer).element).toMatchSnapshot();
  });
});
