import { GlButton, GlLabel, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import ItemWeight from 'ee/boards/components/issue_card_weight.vue';

import StateTooltip from 'ee/related_items_tree/components/state_tooltip.vue';
import TreeItemBody from 'ee/related_items_tree/components/tree_item_body.vue';

import { ChildType } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import ItemDueDate from '~/boards/components/issue_due_date.vue';
import { PathIdSeparator } from '~/related_issues/constants';
import ItemAssignees from '~/issuable/components/issue_assignees.vue';
import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';

import {
  mockParentItem,
  mockInitialConfig,
  mockQueryResponse,
  mockIssue1,
  mockClosedIssue,
  mockEpic1 as mockOpenEpic,
  mockEpic2 as mockClosedEpic,
  mockEpicMeta1,
  mockEpicMeta2,
  mockEpicMeta3,
} from '../mock_data';

Vue.use(Vuex);

let mockItem;

const createIssueItem = (mockIssue = mockIssue1) => {
  return {
    ...mockIssue,
    type: ChildType.Issue,
    pathIdSeparator: PathIdSeparator.Issue,
    assignees: epicUtils.extractIssueAssignees(mockIssue.assignees),
    labels: epicUtils.extractLabels(mockIssue.labels),
  };
};

const createEpicItem = (mockEpic = mockOpenEpic, mockEpicMeta = mockEpicMeta1) => {
  return {
    ...mockEpic,
    type: ChildType.Epic,
    pathIdSeparator: PathIdSeparator.Epic,
    ...mockEpicMeta,
    labels: epicUtils.extractLabels(mockEpic.labels),
  };
};

const createComponent = (parentItem = mockParentItem, item = mockItem) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    isSubItem: false,
    children,
  });
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });

  return shallowMount(TreeItemBody, {
    store,
    propsData: {
      parentItem,
      item,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeItemBody', () => {
    let wrapper;

    const findChildLabels = () => wrapper.findAllComponents(GlLabel);
    const findCountBadge = () => wrapper.findComponent({ ref: 'countBadge' });
    const findEpicHealthStatus = () => wrapper.find('[data-testid="epic-health-status"]');
    const findIssueHealthStatus = () => wrapper.find('[data-testid="issue-health-status"]');
    const findIssueIcon = () => wrapper.findComponent({ ref: 'stateIconMd' });
    const findLink = () => wrapper.findComponent(GlLink);
    const enableHealthStatus = () => {
      wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
        ...mockInitialConfig,
        allowIssuableHealthStatus: true,
      });
    };
    const setShowLabels = async (isShowingLabels) => {
      wrapper.vm.$store.dispatch('setShowLabels', isShowingLabels);

      await nextTick();
    };

    beforeEach(() => {
      mockItem = createIssueItem();
      wrapper = createComponent();
    });

    describe('computed', () => {
      describe('itemReference', () => {
        it('returns value of `item.reference` prop', () => {
          expect(wrapper.vm.itemReference).toBe(mockItem.reference);
        });
      });

      describe('itemWebPath', () => {
        const mockPath = '/foo/bar';

        it('returns value of `item.path`', async () => {
          wrapper.setProps({
            item: { ...mockItem, path: mockPath, webPath: undefined },
          });

          await nextTick();
          expect(wrapper.vm.itemWebPath).toBe(mockPath);
        });

        it('returns value of `item.webPath` when `item.path` is undefined', async () => {
          wrapper.setProps({
            item: { ...mockItem, path: undefined, webPath: mockPath },
          });

          await nextTick();
          expect(wrapper.vm.itemWebPath).toBe(mockPath);
        });
      });

      describe('isOpen', () => {
        it('returns true when `item.state` value is `opened`', async () => {
          wrapper.setProps({
            item: { ...mockItem, state: STATUS_OPEN },
          });

          await nextTick();
          expect(findIssueIcon().attributes('name')).toBe('issues');
        });
      });

      describe('isBlocked', () => {
        it('returns true when `item.blocked` value is `true`', async () => {
          wrapper.setProps({
            item: { ...mockItem, blocked: true },
          });

          await nextTick();
          expect(findIssueIcon().attributes('name')).toBe('issue-block');
        });
      });

      describe('isClosed', () => {
        it('returns true when `item.state` value is `closed`', async () => {
          wrapper.setProps({
            item: { ...mockItem, state: STATUS_CLOSED },
          });

          await nextTick();
          expect(findIssueIcon().attributes('name')).toBe('issue-closed');
        });
      });

      describe('hasMilestone', () => {
        it('returns true when `item.milestone` is defined and has values', () => {
          expect(wrapper.vm.hasMilestone).toBe(true);
        });
      });

      describe('hasAssignees', () => {
        it('returns true when `item.assignees` is defined and has values', () => {
          expect(wrapper.vm.hasAssignees).toBe(true);
        });
      });

      describe('when toggling labels on', () => {
        it('returns true when `item.labels` is defined and has values', async () => {
          expect(findChildLabels().length).toBe(0);

          await setShowLabels(true);

          const labels = findChildLabels();

          expect(labels.length).toBe(1);

          const firstLabel = labels.at(0);

          expect(firstLabel.props('backgroundColor')).toBe(mockIssue1.labels.nodes[0].color);
          expect(firstLabel.props('description')).toBe(mockIssue1.labels.nodes[0].description);
          expect(firstLabel.props('title')).toBe(mockIssue1.labels.nodes[0].title);
        });
      });

      describe('when toggling labels off', () => {
        it('returns true when `item.labels` is defined and has values', async () => {
          await setShowLabels(true);

          expect(findChildLabels().length).toBe(1);

          await setShowLabels(false);

          expect(findChildLabels().length).toBe(0);
        });
      });

      describe('stateText', () => {
        it('returns string `Created` when `item.state` value is `created`', async () => {
          wrapper.setProps({
            item: { ...mockItem, state: STATUS_OPEN },
          });

          await nextTick();
          expect(findIssueIcon().props('ariaLabel')).toBe('Created');
        });

        it('returns string `Closed` when `item.state` value is `closed`', async () => {
          wrapper.setProps({
            item: { ...mockItem, state: STATUS_CLOSED },
          });

          await nextTick();
          expect(findIssueIcon().props('ariaLabel')).toBe('Closed');
        });
      });

      describe('stateIconClass', () => {
        it('returns string `issue-token-state-icon-open gl-text-green-500` when `item.state` value is `opened`', async () => {
          wrapper.setProps({
            item: { ...mockItem, state: STATUS_OPEN },
          });

          await nextTick();
          expect(findIssueIcon().attributes('class')).toContain(
            'issue-token-state-icon-open gl-text-green-500',
          );
        });

        it('return string `gl-text-red-500` when `item.blocked` value is `true`', async () => {
          wrapper.setProps({
            item: { ...mockItem, blocked: true },
          });

          await nextTick();
          expect(findIssueIcon().attributes('class')).toContain('gl-text-red-500');
        });

        it('returns string `issue-token-state-icon-closed gl-text-blue-500` when `item.state` value is `closed`', async () => {
          wrapper.setProps({
            item: { ...mockItem, state: STATUS_CLOSED },
          });

          await nextTick();
          expect(findIssueIcon().attributes('class')).toContain(
            'issue-token-state-icon-closed gl-text-blue-500',
          );
        });
      });

      describe('itemHierarchy', () => {
        it('returns string containing item id and item path', () => {
          const stateTooltip = wrapper.findAllComponents(StateTooltip).at(0);
          expect(stateTooltip.props('path')).toBe('gitlab-org/gitlab-shell#8');
        });
      });

      describe('computedPath', () => {
        it('returns value of `itemWebPath` when it is defined', () => {
          expect(findLink().attributes('href')).toBe(mockItem.webPath);
        });

        it('returns `null` when `itemWebPath` is empty', async () => {
          wrapper.setProps({
            item: { ...mockItem, webPath: '' },
          });

          await nextTick();
          expect(findLink().attributes('href')).toBeUndefined();
        });
      });

      describe.each`
        createItem         | itemType   | isEpic
        ${createEpicItem}  | ${'epic'}  | ${true}
        ${createIssueItem} | ${'issue'} | ${false}
      `(`when dependent on item type`, ({ createItem, isEpic, itemType }) => {
        beforeEach(() => {
          mockItem = createItem();
          wrapper = createComponent();
        });

        describe('isEpic', () => {
          it(`returns ${isEpic} when item type is ${itemType}`, () => {
            expect(wrapper.vm.isEpic).toBe(isEpic);
          });
        });
      });

      describe.each`
        createItem                          | testDesc               | stateIconName
        ${createEpicItem(mockOpenEpic)}     | ${'epic is `open`'}    | ${'epic'}
        ${createEpicItem(mockClosedEpic)}   | ${'epic is `closed`'}  | ${'epic-closed'}
        ${createIssueItem(mockIssue1)}      | ${'issue is `open`'}   | ${'issues'}
        ${createIssueItem(mockClosedIssue)} | ${'issue is `closed`'} | ${'issue-closed'}
      `(`when dependent on item type and state`, ({ createItem, testDesc, stateIconName }) => {
        beforeEach(() => {
          mockItem = createItem;
        });

        describe('stateIconName', () => {
          it(`returns string \`${stateIconName}\` when ${testDesc}`, async () => {
            wrapper.setProps({
              item: mockItem,
            });

            await nextTick();

            expect(findIssueIcon().props('name')).toBe(stateIconName);
          });
        });
      });
    });

    describe('methods', () => {
      describe('handleRemoveClick', () => {
        it('calls `setRemoveItemModalProps` action with params `parentItem` and `item`', () => {
          jest.spyOn(wrapper.vm, 'setRemoveItemModalProps');

          wrapper.vm.handleRemoveClick();

          expect(wrapper.vm.setRemoveItemModalProps).toHaveBeenCalledWith({
            parentItem: mockParentItem,
            item: mockItem,
          });
        });
      });

      describe.each`
        createItem         | expectedFilterUrl                                         | itemType
        ${createEpicItem}  | ${`${mockInitialConfig.epicsWebUrl}?label_name[]=Label`}  | ${'epic'}
        ${createIssueItem} | ${`${mockInitialConfig.issuesWebUrl}?label_name[]=Label`} | ${'issue'}
      `('labelFilterUrl', ({ createItem, expectedFilterUrl, itemType }) => {
        beforeEach(() => {
          mockItem = createItem();
          wrapper = createComponent();
        });

        it(`filterURL for ${itemType} should be ${expectedFilterUrl}`, () => {
          expect(wrapper.vm.labelFilterUrl(mockItem.labels[0])).toBe(expectedFilterUrl);
        });
      });
    });

    describe('template', () => {
      it('renders item body element without class `item-logged-out` when user is signed in', () => {
        expect(wrapper.find('.item-body').classes()).not.toContain('item-logged-out');
      });

      it('renders item body element without class `item-closed` when item state is opened', () => {
        expect(wrapper.find('.item-body').classes()).not.toContain('item-closed');
      });

      it('renders item state icon for large screens', () => {
        const statusIcon = wrapper.findAllComponents(GlIcon).at(0);

        expect(statusIcon.props('name')).toBe('issues');
      });

      it('renders item state tooltip for large screens', () => {
        const stateTooltip = wrapper.findAllComponents(StateTooltip).at(0);

        expect(stateTooltip.props('state')).toBe(mockItem.state);
      });

      it('renders item path in tooltip for large screens', () => {
        const stateTooltip = wrapper.findAllComponents(StateTooltip).at(0);

        const { itemPath, itemId } = wrapper.vm;
        const path = itemPath + mockItem.pathIdSeparator + itemId;

        expect(stateTooltip.props('path')).toBe(path);
        expect(path).toContain('gitlab-org/gitlab-shell');
      });

      it('renders confidential icon when `item.confidential` is true', () => {
        const confidentialIcon = wrapper.findAllComponents(GlIcon).at(1);

        expect(confidentialIcon.isVisible()).toBe(true);
        expect(confidentialIcon.props('name')).toBe('eye-slash');
      });

      it('renders item link', () => {
        expect(findLink().attributes('href')).toBe(mockItem.webPath);
        expect(findLink().text()).toBe(mockItem.title);
      });

      it('renders item state tooltip for medium and small screens', () => {
        const stateTooltip = wrapper.findAllComponents(StateTooltip).at(0);

        expect(stateTooltip.props('state')).toBe(mockItem.state);
      });

      it('renders item milestone when it has milestone', () => {
        const milestone = wrapper.findComponent(ItemMilestone);

        expect(milestone.isVisible()).toBe(true);
      });

      it('renders item due date when it has due date', () => {
        const dueDate = wrapper.findComponent(ItemDueDate);

        expect(dueDate.isVisible()).toBe(true);
      });

      it('does not render red icon for overdue issue that is closed', async () => {
        wrapper.setProps({
          item: {
            ...mockItem,
            closedAt: '2018-12-01T00:00:00.00Z',
          },
        });

        await nextTick();

        expect(wrapper.findComponent(ItemDueDate).props('closed')).toBe(true);
      });

      it('renders item weight when it has weight', () => {
        const weight = wrapper.findComponent(ItemWeight);

        expect(weight.isVisible()).toBe(true);
      });

      it('renders item weight when it has weight of 0', async () => {
        wrapper.setProps({
          item: {
            ...mockItem,
            weight: 0,
          },
        });

        await nextTick();

        const weight = wrapper.findComponent(ItemWeight);

        expect(weight.isVisible()).toBe(true);
        expect(weight.props('weight')).toBe(0);
      });

      it('renders item assignees when it has assignees', () => {
        const assignees = wrapper.findComponent(ItemAssignees);

        expect(assignees.isVisible()).toBe(true);
      });

      it('renders item remove button when `item.userPermissions.canAdminRelation` is true', () => {
        const removeButton = wrapper.findComponent(GlButton);

        expect(removeButton.isVisible()).toBe(true);
        expect(removeButton.attributes('title')).toBe('Remove');
      });

      describe.each`
        createItem         | countBadgeExists | itemType
        ${createEpicItem}  | ${true}          | ${'epic'}
        ${createIssueItem} | ${false}         | ${'issue'}
      `('issue count badge', ({ createItem, countBadgeExists, itemType }) => {
        beforeEach(() => {
          mockItem = createItem();
          wrapper = createComponent();
        });

        it(`${
          countBadgeExists ? 'renders' : 'does not render'
        } issue count badge when item type is ${itemType}`, () => {
          expect(findCountBadge().exists()).toBe(countBadgeExists);
        });
      });

      describe('health status', () => {
        it('renders when feature is available', async () => {
          expect(findIssueHealthStatus().exists()).toBe(false);

          enableHealthStatus();

          await nextTick();

          expect(findIssueHealthStatus().exists()).toBe(true);
        });

        describe.each`
          mockIssue          | showHealthStatus
          ${mockIssue1}      | ${true}
          ${mockClosedIssue} | ${false}
        `("for '$mockIssue.state' issue", ({ mockIssue, showHealthStatus }) => {
          beforeEach(() => {
            mockItem = createIssueItem(mockIssue);
            wrapper = createComponent();
            enableHealthStatus();
          });

          it(`${showHealthStatus ? 'renders' : 'does not render'} health status`, () => {
            expect(findIssueHealthStatus().exists()).toBe(showHealthStatus);
          });
        });

        describe.each`
          mockEpic          | mockEpicMeta     | childIssues        | showHealthStatus
          ${mockOpenEpic}   | ${mockEpicMeta1} | ${'open issue(s)'} | ${true}
          ${mockOpenEpic}   | ${mockEpicMeta2} | ${'closed'}        | ${false}
          ${mockClosedEpic} | ${mockEpicMeta1} | ${'open issue(s)'} | ${true}
          ${mockClosedEpic} | ${mockEpicMeta2} | ${'closed issues'} | ${false}
          ${mockClosedEpic} | ${mockEpicMeta3} | ${'no issues'}     | ${false}
        `(
          "for '$mockEpic.state' epic with '$childIssues'",
          ({ mockEpic, mockEpicMeta, showHealthStatus }) => {
            beforeEach(() => {
              mockItem = createEpicItem(mockEpic, mockEpicMeta);

              wrapper = createComponent();
              enableHealthStatus();
            });

            it(`${showHealthStatus ? 'renders' : 'does not render'} health status`, () => {
              expect(findEpicHealthStatus().exists()).toBe(showHealthStatus);
            });
          },
        );
      });
    });
  });
});
