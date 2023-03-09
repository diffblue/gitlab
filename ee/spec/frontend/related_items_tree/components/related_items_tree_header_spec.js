import { GlPopover, GlIcon, GlAlert } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import EpicHealthStatus from 'ee/related_items_tree/components/epic_health_status.vue';
import EpicActionsSplitButton from 'ee/related_items_tree/components/epic_issue_actions_split_button.vue';
import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { mockInitialConfig, mockParentItem, mockQueryResponse } from '../mock_data';

Vue.use(Vuex);

const createComponent = ({ slots } = {}) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    isSubItem: false,
    children,
  });
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });
  store.dispatch('setWeightSum', {
    openedIssues: 10,
    closedIssues: 5,
  });
  store.dispatch('setChildrenCount', mockParentItem.descendantCounts);

  return shallowMountExtended(RelatedItemsTreeHeader, {
    store,
    slots,
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedItemsTreeHeader', () => {
    let wrapper;

    const findToggleButton = () => wrapper.findByTestId('toggle-links');

    const findEpicsIssuesSplitButton = () => wrapper.findComponent(EpicActionsSplitButton);

    describe('Count popover', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('returns string containing epic count based on available direct children within state', () => {
        expect(wrapper.findComponent(GlPopover).text()).toContain(`Epics •
            1 open, 1 closed`);
      });

      it('returns string containing issue count based on available direct children within state', () => {
        expect(wrapper.findComponent(GlPopover).text()).toContain(`Issues •
            2 open, 1 closed`);
      });

      it('displays warning', () => {
        expect(wrapper.findComponent(GlAlert).text()).toBe(
          'Counts reflect children you may not have access to.',
        );
      });
    });

    describe('totalWeight', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('total of openedIssues and closedIssues weight', () => {
        expect(wrapper.vm.totalWeight).toBe(15);
      });
    });

    describe('epic issue actions split button', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      describe('showAddEpicForm event', () => {
        let toggleAddItemForm;

        beforeEach(() => {
          toggleAddItemForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleAddItemForm,
            },
          });
        });

        it('dispatches toggleAddItemForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showAddEpicForm');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.mock.calls[0][1];

          expect(payload).toEqual({
            issuableType: TYPE_EPIC,
            toggleState: true,
          });
        });
      });

      describe('showCreateEpicForm event', () => {
        let toggleCreateEpicForm;

        beforeEach(() => {
          toggleCreateEpicForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleCreateEpicForm,
            },
          });
        });

        it('dispatches toggleCreateEpicForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showCreateEpicForm');

          expect(toggleCreateEpicForm).toHaveBeenCalled();

          const payload =
            toggleCreateEpicForm.mock.calls[toggleCreateEpicForm.mock.calls.length - 1][1];

          expect(payload).toEqual({ toggleState: true });
        });
      });

      describe('showAddIssueForm event', () => {
        let toggleAddItemForm;
        let setItemInputValue;

        beforeEach(() => {
          toggleAddItemForm = jest.fn();
          setItemInputValue = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleAddItemForm,
              setItemInputValue,
            },
          });
        });

        it('dispatches toggleAddItemForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showAddIssueForm');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.mock.calls[0][1];

          expect(payload).toEqual({
            issuableType: TYPE_ISSUE,
            toggleState: true,
          });
        });
      });

      describe('showCreateIssueForm event', () => {
        let toggleCreateIssueForm;

        beforeEach(() => {
          toggleCreateIssueForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleCreateIssueForm,
            },
          });
        });

        it('dispatches toggleCreateIssueForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showCreateIssueForm');

          expect(toggleCreateIssueForm).toHaveBeenCalled();

          const payload =
            toggleCreateIssueForm.mock.calls[toggleCreateIssueForm.mock.calls.length - 1][1];

          expect(payload).toEqual({ toggleState: true });
        });
      });
    });

    describe('template', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('renders item badges container', () => {
        const badgesContainerEl = wrapper.find('.issue-count-badge');

        expect(badgesContainerEl.isVisible()).toBe(true);
      });

      it('renders epics count and gl-icon', () => {
        const epicsEl = wrapper.findAll('.issue-count-badge > span').at(0);
        const epicIcon = epicsEl.findComponent(GlIcon);

        expect(epicsEl.text().trim()).toContain('2');
        expect(epicIcon.isVisible()).toBe(true);
        expect(epicIcon.props('name')).toBe('epic');
      });

      it('renders `Add` dropdown button', () => {
        expect(findEpicsIssuesSplitButton().isVisible()).toBe(true);
      });

      describe('when issuable-health-status feature is not available', () => {
        beforeEach(async () => {
          wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
            ...mockInitialConfig,
            allowIssuableHealthStatus: false,
          });

          await nextTick();
        });

        it('does not render health status', () => {
          expect(wrapper.findComponent(EpicHealthStatus).exists()).toBe(false);
        });
      });

      describe('when issuable-health-status feature is available', () => {
        beforeEach(async () => {
          wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
            ...mockInitialConfig,
            allowIssuableHealthStatus: true,
          });

          await nextTick();
        });

        it('does not render health status', () => {
          expect(wrapper.findComponent(EpicHealthStatus).exists()).toBe(true);
        });
      });

      it('renders issues count and gl-icon', () => {
        const issuesEl = wrapper.findAll('.issue-count-badge > span').at(1);
        const issueIcon = issuesEl.findComponent(GlIcon);

        expect(issuesEl.text().trim()).toContain('3');
        expect(issueIcon.isVisible()).toBe(true);
        expect(issueIcon.props('name')).toBe('issues');
      });

      it('renders totalWeight count and gl-icon', () => {
        const weightEl = wrapper.findAll('.issue-count-badge > span').at(2);
        const weightIcon = weightEl.findComponent(GlIcon);

        expect(weightEl.text().trim()).toContain('15');
        expect(weightIcon.isVisible()).toBe(true);
        expect(weightIcon.props('name')).toBe('weight');
      });
    });

    describe('toggle Child issues and epics section', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('is expanded by default', () => {
        expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
      });

      it('expands on click toggle button', async () => {
        findToggleButton().vm.$emit('click');
        await nextTick();

        expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
        expect(wrapper.emitted('toggleRelatedItemsView')[0][0]).toBe(false);
      });

      it('Collapse on click toggle button', async () => {
        findToggleButton().vm.$emit('click');
        findToggleButton().vm.$emit('click');
        await nextTick();

        expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
        expect(wrapper.emitted('toggleRelatedItemsView')[1][0]).toBe(true);
      });
    });
  });
});
