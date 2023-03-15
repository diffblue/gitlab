import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';

import EpicSidebar from 'ee/epic/components/epic_sidebar.vue';
import { getStoreConfig } from 'ee/epic/store';

import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';

import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarReferenceWidget from '~/sidebar/components/copy/sidebar_reference_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import { parsePikadayDate } from '~/lib/utils/datetime_utility';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicSidebarComponent', () => {
  let wrapper;
  let store;

  const createComponent = ({ actions: actionMocks } = {}) => {
    const { actions, state, ...storeConfig } = getStoreConfig();
    store = new Vuex.Store({
      ...storeConfig,
      state: {
        ...state,
        ...mockEpicMeta,
        ...mockEpicData,
      },

      actions: { ...actions, ...actionMocks },
    });

    return shallowMount(EpicSidebar, {
      store,
      provide: {
        iid: '1',
      },
    });
  };

  describe('template', () => {
    beforeEach(() => {
      gon.current_user_id = 1;

      wrapper = createComponent();
    });

    it('renders component container element with classes `right-sidebar-expanded`, `right-sidebar` & `epic-sidebar`', async () => {
      store.dispatch('toggleSidebarFlag', false);

      await nextTick();

      expect(wrapper.classes()).toContain('right-sidebar-expanded');
      expect(wrapper.classes()).toContain('right-sidebar');
      expect(wrapper.classes()).toContain('epic-sidebar');
    });

    it('renders header container element with classes `issuable-sidebar` & `js-issuable-update`', () => {
      expect(wrapper.find('.issuable-sidebar.js-issuable-update').exists()).toBe(true);
    });

    it('renders Start date & Due date elements when sidebar is expanded', async () => {
      wrapper.vm.$store.dispatch('toggleSidebarFlag', false);

      await nextTick();

      const startDateEl = wrapper.find('[data-testid="start-date"]');
      const dueDateEl = wrapper.find('[data-testid="due-date"]');

      expect(startDateEl.exists()).toBe(true);
      expect(startDateEl.props()).toMatchObject({
        iid: '1',
        fullPath: 'frontend-fixtures-group',
        issuableType: 'epic',
        dateType: 'startDate',
        canInherit: true,
      });

      expect(dueDateEl.exists()).toBe(true);
      expect(dueDateEl.props()).toMatchObject({
        iid: '1',
        fullPath: 'frontend-fixtures-group',
        issuableType: 'epic',
        dateType: 'dueDate',
        canInherit: true,
      });
    });

    it('renders labels select element', () => {
      expect(wrapper.find('[data-testid="labels-select"]').exists()).toBe(true);
    });

    it('renders SidebarSubscriptionsWidget', () => {
      expect(wrapper.findComponent(SidebarSubscriptionsWidget).exists()).toBe(true);
    });

    it('renders SidebarTodoWidget when user is signed in', () => {
      const todoWidget = wrapper.findComponent(SidebarTodoWidget);
      expect(todoWidget.exists()).toBe(true);
      expect(todoWidget.props()).toMatchObject({
        issuableId: `gid://gitlab/Epic/${mockEpicMeta.epicId}`,
        issuableIid: '1',
        fullPath: 'frontend-fixtures-group',
        issuableType: 'epic',
      });
    });

    it('renders SidebarReferenceWidget', () => {
      expect(wrapper.findComponent(SidebarReferenceWidget).exists()).toBe(true);
    });

    describe('when sub-epics feature is not available', () => {
      it('does not renders ancestors list', async () => {
        store.dispatch('setEpicMeta', {
          ...mockEpicMeta,
          allowSubEpics: false,
        });

        await nextTick();

        expect(wrapper.findComponent(SidebarAncestorsWidget).exists()).toBe(false);
      });
    });

    describe('when sub-epics feature is available', () => {
      it('renders ancestors list', () => {
        expect(wrapper.findComponent(SidebarAncestorsWidget).exists()).toBe(true);
      });
    });

    it('renders participants widget', () => {
      expect(wrapper.findComponent(SidebarParticipantsWidget).exists()).toBe(true);
    });

    it('renders subscription toggle element', () => {
      expect(wrapper.find('[data-testid="subscribe"]').exists()).toBe(true);
    });
  });

  describe('when user is not signed in', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render SidebarTodoWidget', () => {
      expect(wrapper.findComponent(SidebarTodoWidget).exists()).toBe(false);
    });
  });

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('makes request to get epic details', () => {
      const actionSpies = {
        fetchEpicDetails: jest.fn(),
      };

      const wrapperWithMethod = createComponent({
        actions: actionSpies,
      });

      expect(actionSpies.fetchEpicDetails).toHaveBeenCalled();

      wrapperWithMethod.destroy();
    });
  });

  describe('sidebardatewidget dates', () => {
    const mockDate = '2023-03-01';

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('sets min date when start date is selected', () => {
      const startDateWidget = wrapper.find('[data-testid="start-date"]');
      startDateWidget.vm.$emit('startDateUpdated', mockDate);

      expect(wrapper.vm.minDate).toStrictEqual(parsePikadayDate(mockDate));
    });

    it('sets max date when due date is selected', () => {
      const dueDateWidget = wrapper.find('[data-testid="due-date"]');
      dueDateWidget.vm.$emit('dueDateUpdated', mockDate);

      expect(wrapper.vm.maxDate).toStrictEqual(parsePikadayDate(mockDate));
    });
  });
});
