import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';

import EpicSidebar from 'ee/epic/components/epic_sidebar.vue';
import { dateTypes } from 'ee/epic/constants';
import { getStoreConfig } from 'ee/epic/store';

import epicUtils from 'ee/epic/utils/epic_utils';

import SidebarAncestorsWidget from 'ee_component/sidebar/components/ancestors_tree/sidebar_ancestors_widget.vue';

import { parsePikadayDate } from '~/lib/utils/datetime_utility';

import SidebarParticipantsWidget from '~/sidebar/components/participants/sidebar_participants_widget.vue';
import SidebarReferenceWidget from '~/sidebar/components/reference/sidebar_reference_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicSidebarComponent', () => {
  const originalUserId = gon.current_user_id;
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

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('getDateFromMilestonesTooltip', () => {
      it('calls `epicUtils.getDateFromMilestonesTooltip` with `dateType` param', () => {
        jest.spyOn(epicUtils, 'getDateFromMilestonesTooltip');

        wrapper.vm.getDateFromMilestonesTooltip(dateTypes.start);

        expect(epicUtils.getDateFromMilestonesTooltip).toHaveBeenCalledWith(
          expect.objectContaining({
            dateType: dateTypes.start,
          }),
        );
      });
    });

    describe('changeStartDateType', () => {
      it('calls `toggleStartDateType` on component with `dateTypeIsFixed` param', () => {
        jest.spyOn(wrapper.vm, 'toggleStartDateType');

        wrapper.vm.changeStartDateType({ dateTypeIsFixed: true, typeChangeOnEdit: true });

        expect(wrapper.vm.toggleStartDateType).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
          }),
        );
      });

      it('calls `saveDate` on component when `typeChangeOnEdit` param false', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.changeStartDateType({ dateTypeIsFixed: true, typeChangeOnEdit: false });

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.start,
            newDate: '2018-06-01',
          }),
        );
      });
    });

    describe('saveStartDate', () => {
      it('calls `saveDate` on component with `date` param set to `newDate`', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.saveStartDate('2018-1-1');

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.start,
            newDate: '2018-1-1',
          }),
        );
      });
    });

    describe('changeDueDateType', () => {
      it('calls `toggleDueDateType` on component with `dateTypeIsFixed` param', () => {
        jest.spyOn(wrapper.vm, 'toggleDueDateType');

        wrapper.vm.changeDueDateType({ dateTypeIsFixed: true, typeChangeOnEdit: true });

        expect(wrapper.vm.toggleDueDateType).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
          }),
        );
      });

      it('calls `saveDate` on component when `typeChangeOnEdit` param false', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.changeDueDateType({ dateTypeIsFixed: true, typeChangeOnEdit: false });

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.due,
            newDate: '2018-08-01',
          }),
        );
      });
    });

    describe('saveDueDate', () => {
      it('calls `saveDate` on component with `date` param set to `newDate`', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.saveDueDate('2018-1-1');

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.due,
            newDate: '2018-1-1',
          }),
        );
      });
    });
  });

  describe('template', () => {
    beforeAll(() => {
      gon.current_user_id = 1;
    });

    afterAll(() => {
      gon.current_user_id = originalUserId;
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
        label: 'Start date',
        dateFixed: parsePikadayDate(mockEpicMeta.startDateFixed),
      });

      expect(dueDateEl.exists()).toBe(true);
      expect(dueDateEl.props()).toMatchObject({
        label: 'Due date',
        dateFixed: parsePikadayDate(mockEpicMeta.dueDateFixed),
      });
    });

    it('renders labels select element', () => {
      expect(wrapper.find('[data-testid="labels-select"]').exists()).toBe(true);
    });

    it('renders SidebarSubscriptionsWidget', () => {
      expect(wrapper.find(SidebarSubscriptionsWidget).exists()).toBe(true);
    });

    it('renders SidebarTodoWidget when user is signed in', () => {
      const todoWidget = wrapper.find(SidebarTodoWidget);
      expect(todoWidget.exists()).toBe(true);
      expect(todoWidget.props()).toMatchObject({
        issuableId: 'gid://gitlab/Epic/1',
        issuableIid: '1',
        fullPath: 'frontend-fixtures-group',
        issuableType: 'epic',
      });
    });

    it('renders SidebarReferenceWidget', () => {
      expect(wrapper.find(SidebarReferenceWidget).exists()).toBe(true);
    });

    describe('when sub-epics feature is not available', () => {
      it('does not renders ancestors list', async () => {
        store.dispatch('setEpicMeta', {
          ...mockEpicMeta,
          allowSubEpics: false,
        });

        await nextTick();

        expect(wrapper.find(SidebarAncestorsWidget).exists()).toBe(false);
      });
    });

    describe('when sub-epics feature is available', () => {
      it('renders ancestors list', () => {
        expect(wrapper.find(SidebarAncestorsWidget).exists()).toBe(true);
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
      gon.current_user_id = null;
    });

    it('does not render SidebarTodoWidget', () => {
      expect(wrapper.find(SidebarTodoWidget).exists()).toBe(false);
    });
  });

  describe('mounted', () => {
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
});
