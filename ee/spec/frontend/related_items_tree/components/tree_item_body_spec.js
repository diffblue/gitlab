import { GlButton, GlLabel, GlLink, GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
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
let store;

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

describe('RelatedItemsTree', () => {
  describe('TreeItemBody', () => {
    let wrapper;

    const createComponent = ({ parentItem = mockParentItem, item = mockItem } = {}) => {
      store = createDefaultStore();
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

      wrapper = shallowMount(TreeItemBody, {
        store,
        propsData: {
          parentItem,
          item,
        },
      });
    };

    const findStateTooltip = () => wrapper.findAllComponents(StateTooltip);
    const findRemoveButton = () => wrapper.findComponent(GlButton);
    const findChildLabels = () => wrapper.findAllComponents(GlLabel);
    const findTooltip = () => wrapper.findComponent(GlTooltip);
    const findItemMilestone = () => wrapper.findComponent(ItemMilestone);
    const findItemAssignees = () => wrapper.findComponent(ItemAssignees);
    const findAllIcons = () => wrapper.findAllComponents(GlIcon);
    const findCountBadge = () => wrapper.findComponent({ ref: 'countBadge' });
    const findEpicHealthStatus = () => wrapper.find('[data-testid="epic-health-status"]');
    const findIssueHealthStatus = () => wrapper.find('[data-testid="issue-health-status"]');
    const findIssueIcon = () => wrapper.findComponent({ ref: 'stateIconMd' });
    const findLink = () => wrapper.findComponent(GlLink);
    const enableHealthStatus = () => {
      store.commit('SET_INITIAL_CONFIG', {
        ...mockInitialConfig,
        allowIssuableHealthStatus: true,
      });
    };
    const setShowLabels = async (isShowingLabels) => {
      store.dispatch('setShowLabels', isShowingLabels);

      await nextTick();
    };

    beforeEach(() => {
      mockItem = createIssueItem();
      createComponent();
    });

    describe('Component state', () => {
      describe('itemReference', () => {
        it('renders value of `item.reference` prop in tooltip path', () => {
          expect(findStateTooltip().at(0).props('path')).toBe(mockItem.reference);
        });
      });

      describe('WebPath', () => {
        const mockPath = '/foo/bar';

        it('renders value of `item.path` for a link', () => {
          createComponent({
            item: { ...mockItem, path: mockPath, webPath: undefined },
          });

          expect(findLink().attributes('href')).toBe(mockPath);
        });

        it('renders value of `item.webPath` when `item.path` is undefined for a link', () => {
          createComponent({
            item: { ...mockItem, path: mockPath, webPath: undefined },
          });

          expect(findLink().attributes('href')).toBe(mockPath);
        });
      });

      describe('isOpen', () => {
        it('correctly sets icon name attribute when `item.state` value is `opened`', () => {
          createComponent({
            item: { ...mockItem, state: STATUS_OPEN },
          });

          expect(findIssueIcon().attributes('name')).toBe('issues');
        });
      });

      describe('isBlocked', () => {
        it('correctly sets icon name attribute issue-block when `item.blocked` value is `true`', () => {
          createComponent({
            item: { ...mockItem, blocked: true },
          });

          expect(findIssueIcon().attributes('name')).toBe('issue-block');
        });
      });

      describe('isClosed', () => {
        it('correctly sets icon name attribute when `item.state` value is `closed`', () => {
          createComponent({
            item: { ...mockItem, state: STATUS_CLOSED },
          });

          expect(findIssueIcon().attributes('name')).toBe('issue-closed');
        });
      });

      describe('milestones', () => {
        it('renders milestone component `item.milestone` is defined and has values', () => {
          expect(findItemMilestone().exists()).toBe(true);
        });
      });

      describe('assignees', () => {
        it('renders assignees component when assignees defined and has values', () => {
          expect(findItemAssignees().exists()).toBe(true);
        });
      });

      describe('when toggling labels on', () => {
        it('renders labels `item.labels` is defined and has values', async () => {
          expect(findChildLabels()).toHaveLength(0);

          await setShowLabels(true);

          const labels = findChildLabels();

          expect(labels).toHaveLength(1);

          const firstLabel = labels.at(0);

          expect(firstLabel.props('backgroundColor')).toBe(mockIssue1.labels.nodes[0].color);
          expect(firstLabel.props('description')).toBe(mockIssue1.labels.nodes[0].description);
          expect(firstLabel.props('title')).toBe(mockIssue1.labels.nodes[0].title);
        });
      });

      describe('when toggling labels off', () => {
        it('does not render labels when `item.labels` is defined and has values', async () => {
          await setShowLabels(true);

          expect(findChildLabels()).toHaveLength(1);

          await setShowLabels(false);

          expect(findChildLabels()).toHaveLength(0);
        });
      });

      describe('state text', () => {
        it('renders `Created` aria label for an icon when `item.state` value is `created`', () => {
          createComponent({
            item: { ...mockItem, state: STATUS_OPEN },
          });

          expect(findIssueIcon().props('ariaLabel')).toBe('Created');
        });

        it('renders `Closed` aria label for an icon when `item.state` value is `closed`', () => {
          createComponent({
            item: { ...mockItem, state: STATUS_CLOSED },
          });

          expect(findIssueIcon().props('ariaLabel')).toBe('Closed');
        });
      });

      describe('icons', () => {
        it('applies correct icon styling when `item.state` value is `opened`', () => {
          createComponent({
            item: { ...mockItem, state: STATUS_OPEN },
          });

          expect(findIssueIcon().attributes('class')).toContain(
            'issue-token-state-icon-open gl-text-green-500',
          );
        });

        it('applies correct icon styling when `item.blocked` value is `true`', () => {
          createComponent({
            item: { ...mockItem, blocked: true },
          });

          expect(findIssueIcon().attributes('class')).toContain('gl-text-red-500');
        });

        it('applies correct icon styling when `item.state` value is `closed`', () => {
          createComponent({
            item: { ...mockItem, state: STATUS_CLOSED },
          });

          expect(findIssueIcon().attributes('class')).toContain(
            'issue-token-state-icon-closed gl-text-blue-500',
          );
        });
      });

      describe('itemHierarchy', () => {
        it('renders correct tooltip path', () => {
          expect(findStateTooltip().at(0).props('path')).toBe('gitlab-org/gitlab-shell#8');
        });
      });

      describe('computedPath', () => {
        it('renders `itemWebPath` as tooltip path when path it is defined', () => {
          expect(findLink().attributes('href')).toBe(mockItem.webPath);
        });

        it('does not render href when both `path` and `itemWebPath` are not defined', () => {
          createComponent({
            item: { ...mockItem, webPath: '' },
          });

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
          createComponent();
        });

        describe('isEpic', () => {
          it(`renders tooltip when item type is ${itemType}`, () => {
            expect(findTooltip().exists()).toBe(isEpic);
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
          it(`renders \`${stateIconName}\` as icon name when ${testDesc}`, () => {
            createComponent({
              item: mockItem,
            });

            expect(findIssueIcon().props('name')).toBe(stateIconName);
          });
        });
      });
    });

    describe('interactions', () => {
      describe('removing', () => {
        it('calls `setRemoveItemModalProps` action with params `parentItem` and `item`', () => {
          jest.spyOn(store, 'dispatch');
          findRemoveButton().vm.$emit('click');

          expect(store.dispatch).toHaveBeenCalledWith('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: mockItem,
          });
        });
      });

      describe.each`
        createItem         | expectedFilterUrl                                         | itemType
        ${createEpicItem}  | ${`${mockInitialConfig.epicsWebUrl}?label_name[]=Label`}  | ${'epic'}
        ${createIssueItem} | ${`${mockInitialConfig.issuesWebUrl}?label_name[]=Label`} | ${'issue'}
      `('labels', ({ createItem, expectedFilterUrl, itemType }) => {
        beforeEach(async () => {
          mockItem = createItem();
          createComponent({
            item: createItem(),
          });

          await setShowLabels(true);
        });

        it(`label target for ${itemType} should be ${expectedFilterUrl}`, () => {
          expect(findChildLabels().at(0).props('target')).toBe(expectedFilterUrl);
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
        expect(findAllIcons().at(0).props('name')).toBe('issues');
      });

      it('renders item state tooltip for large screens', () => {
        expect(findStateTooltip().at(0).props('state')).toBe(mockItem.state);
      });

      it('renders item path in tooltip for large screens', () => {
        const path = 'gitlab-org/gitlab-shell#8';

        expect(findStateTooltip().at(0).props('path')).toBe(path);
        expect(path).toContain('gitlab-org/gitlab-shell');
      });

      it('renders confidential icon when `item.confidential` is true', () => {
        const confidentialIcon = findAllIcons().at(1);

        expect(confidentialIcon.isVisible()).toBe(true);
        expect(confidentialIcon.props('name')).toBe('eye-slash');
      });

      it('renders item link', () => {
        expect(findLink().attributes('href')).toBe(mockItem.webPath);
        expect(findLink().text()).toBe(mockItem.title);
      });

      it('renders item state tooltip for medium and small screens', () => {
        expect(findStateTooltip().at(0).props('state')).toBe(mockItem.state);
      });

      it('renders item milestone when it has milestone', () => {
        expect(findItemMilestone().isVisible()).toBe(true);
      });

      it('renders item due date when it has due date', () => {
        const dueDate = wrapper.findComponent(ItemDueDate);

        expect(dueDate.isVisible()).toBe(true);
      });

      it('does not render red icon for overdue issue that is closed', () => {
        createComponent({
          item: {
            ...mockItem,
            closedAt: '2018-12-01T00:00:00.00Z',
          },
        });

        expect(wrapper.findComponent(ItemDueDate).props('closed')).toBe(true);
      });

      it('renders item weight when it has weight', () => {
        const weight = wrapper.findComponent(ItemWeight);

        expect(weight.isVisible()).toBe(true);
      });

      it('renders item weight when it has weight of 0', () => {
        createComponent({
          item: {
            ...mockItem,
            weight: 0,
          },
        });

        const weight = wrapper.findComponent(ItemWeight);

        expect(weight.isVisible()).toBe(true);
        expect(weight.props('weight')).toBe(0);
      });

      it('renders item assignees when it has assignees', () => {
        expect(findItemAssignees().isVisible()).toBe(true);
      });

      it('renders item remove button when `item.userPermissions.canAdminRelation` is true', () => {
        expect(findRemoveButton().isVisible()).toBe(true);
        expect(findRemoveButton().attributes('title')).toBe('Remove');
      });

      describe.each`
        createItem         | countBadgeExists | itemType
        ${createEpicItem}  | ${true}          | ${'epic'}
        ${createIssueItem} | ${false}         | ${'issue'}
      `('issue count badge', ({ createItem, countBadgeExists, itemType }) => {
        beforeEach(() => {
          mockItem = createItem();
          createComponent();
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
            createComponent();
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

              createComponent();
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
