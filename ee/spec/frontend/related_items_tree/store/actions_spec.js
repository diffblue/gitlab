import MockAdapter from 'axios-mock-adapter';
import mockProjects from 'test_fixtures_static/projects.json';
import {
  ChildType,
  SNOWPLOW_EPIC_ACTIVITY,
  trackingAddedIssue,
  EPIC_CREATE_ERROR_MESSAGE,
} from 'ee/related_items_tree/constants';
import * as actions from 'ee/related_items_tree/store/actions';
import * as types from 'ee/related_items_tree/store/mutation_types';
import createDefaultState from 'ee/related_items_tree/store/state';

import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import Tracking from '~/tracking';

import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import { createAlert } from '~/alert';
import { STATUS_OPEN, TYPE_EPIC } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { itemAddFailureTypesMap, PathIdSeparator } from '~/related_issues/constants';

import {
  mockInitialConfig,
  mockParentItem,
  mockParentItem2,
  mockQueryResponse,
  mockEpicTreeReorderInput,
  mockReorderMutationResponse,
  mockEpics,
  mockIssues,
  mockEpic1,
  mockDefaultProjectForIssueCreation,
} from '../mock_data';

jest.mock('~/alert');

describe('RelatedItemTree', () => {
  afterEach(() => {
    createAlert.mockClear();
  });

  describe('store', () => {
    describe('actions', () => {
      let state;
      const mockItems = mockEpics.map((item) =>
        epicUtils.formatChildItem(Object.assign(item, { type: ChildType.Epic })),
      );

      beforeEach(() => {
        state = createDefaultState();
      });

      describe('setInitialConfig', () => {
        it('should set initial config on state', () => {
          testAction(
            actions.setInitialConfig,
            mockInitialConfig,
            {},
            [{ type: types.SET_INITIAL_CONFIG, payload: mockInitialConfig }],
            [],
          );
        });
      });

      describe('setInitialParentItem', () => {
        it('should set initial parentItem on state', () => {
          testAction(
            actions.setInitialParentItem,
            mockParentItem,
            {},
            [{ type: types.SET_INITIAL_PARENT_ITEM, payload: mockParentItem }],
            [],
          );
        });
      });

      describe('setChildrenCount', () => {
        it('should set initial descendantCounts on state', () => {
          testAction(
            actions.setChildrenCount,
            mockParentItem.descendantCounts,
            {},
            [{ type: types.SET_CHILDREN_COUNT, payload: mockParentItem.descendantCounts }],
            [],
          );
        });

        it('should persist non overwritten descendantCounts state', () => {
          const descendantCounts = { openedEpics: 9 };
          testAction(
            actions.setChildrenCount,
            descendantCounts,
            { descendantCounts: mockParentItem.descendantCounts },
            [
              {
                type: types.SET_CHILDREN_COUNT,
                payload: { ...mockParentItem.descendantCounts, ...descendantCounts },
              },
            ],
            [],
          );
        });
      });

      describe('updateChildrenCount', () => {
        const mockEpicsWithType = mockEpics.map((item) => ({ ...item, type: ChildType.Epic }));

        const mockIssuesWithType = mockIssues.map((item) => ({ ...item, type: ChildType.Issue }));

        it('should update openedEpics, by incrementing it', () => {
          testAction(
            actions.updateChildrenCount,
            { item: mockEpicsWithType[0], isRemoved: false },
            { descendantCounts: mockParentItem.descendantCounts },
            [],
            [
              {
                type: 'setChildrenCount',
                payload: { openedEpics: mockParentItem.descendantCounts.openedEpics + 1 },
              },
            ],
          );
        });

        it('should update openedIssues, by incrementing it', () => {
          testAction(
            actions.updateChildrenCount,
            { item: mockIssuesWithType[0], isRemoved: false },
            { descendantCounts: mockParentItem.descendantCounts },
            [],
            [
              {
                type: 'setChildrenCount',
                payload: { openedIssues: mockParentItem.descendantCounts.openedIssues + 1 },
              },
            ],
          );
        });

        it('should update openedEpics, by decrementing it', () => {
          testAction(
            actions.updateChildrenCount,
            { item: mockEpicsWithType[0], isRemoved: true },
            { descendantCounts: mockParentItem.descendantCounts },
            [],
            [
              {
                type: 'setChildrenCount',
                payload: { openedEpics: mockParentItem.descendantCounts.openedEpics - 1 },
              },
            ],
          );
        });

        it('should update openedIssues, by decrementing it', () => {
          testAction(
            actions.updateChildrenCount,
            { item: mockIssuesWithType[0], isRemoved: true },
            { descendantCounts: mockParentItem.descendantCounts },
            [],
            [
              {
                type: 'setChildrenCount',
                payload: { openedIssues: mockParentItem.descendantCounts.openedIssues - 1 },
              },
            ],
          );
        });
      });

      describe('expandItem', () => {
        it('should set `itemExpanded` to true on state.childrenFlags', () => {
          testAction(actions.expandItem, {}, {}, [{ type: types.EXPAND_ITEM, payload: {} }], []);
        });
      });

      describe('collapseItem', () => {
        it('should set `itemExpanded` to false on state.childrenFlags', () => {
          testAction(
            actions.collapseItem,
            {},
            {},
            [{ type: types.COLLAPSE_ITEM, payload: {} }],
            [],
          );
        });
      });

      describe('setItemChildren', () => {
        const mockPayload = {
          children: ['foo'],
          parentItem: mockParentItem,
          isSubItem: false,
          append: false,
        };

        it('should set provided `children` values on state.children with provided parentItem.reference key', () => {
          testAction(
            actions.setItemChildren,
            mockPayload,
            {},
            [
              {
                type: types.SET_ITEM_CHILDREN,
                payload: mockPayload,
              },
            ],
            [],
          );
        });

        it('should set provided `children` values on state.children with provided parentItem.reference key and also dispatch action `expandItem` when isSubItem param is true', () => {
          mockPayload.isSubItem = true;

          testAction(
            actions.setItemChildren,
            mockPayload,
            {},
            [
              {
                type: types.SET_ITEM_CHILDREN,
                payload: mockPayload,
              },
            ],
            [
              {
                type: 'expandItem',
                payload: { parentItem: mockPayload.parentItem },
              },
            ],
          );
        });
      });

      describe('setItemChildrenFlags', () => {
        it('should set `state.childrenFlags` for every item in provided children param', () => {
          testAction(
            actions.setItemChildrenFlags,
            { children: [{ reference: '&1' }] },
            {},
            [{ type: types.SET_ITEM_CHILDREN_FLAGS, payload: { children: [{ reference: '&1' }] } }],
            [],
          );
        });
      });

      describe('setEpicPageInfo', () => {
        it('should set `epicEndCursor` and `hasMoreEpics` to `state.childrenFlags`', () => {
          const { pageInfo } = mockQueryResponse.data.group.epic.children;

          testAction(
            actions.setEpicPageInfo,
            { parentItem: mockParentItem, pageInfo },
            {},
            [
              {
                type: types.SET_EPIC_PAGE_INFO,
                payload: { parentItem: mockParentItem, pageInfo },
              },
            ],
            [],
          );
        });
      });

      describe('setIssuePageInfo', () => {
        it('should set `issueEndCursor` and `hasMoreIssues` to `state.childrenFlags`', () => {
          const { pageInfo } = mockQueryResponse.data.group.epic.issues;

          testAction(
            actions.setIssuePageInfo,
            { parentItem: mockParentItem, pageInfo },
            {},
            [
              {
                type: types.SET_ISSUE_PAGE_INFO,
                payload: { parentItem: mockParentItem, pageInfo },
              },
            ],
            [],
          );
        });
      });

      describe('setWeightSum', () => {
        it('set weightSum', () => {
          const descendantWeightSum = mockQueryResponse.data.group.epic;
          testAction(
            actions.setWeightSum,
            descendantWeightSum,
            {},
            [
              {
                type: types.SET_WEIGHT_SUM,
                payload: descendantWeightSum,
              },
            ],
            [],
          );
        });
      });

      describe('requestItems', () => {
        it('should set `state.itemsFetchInProgress` to true', () => {
          testAction(
            actions.requestItems,
            {},
            {},
            [{ type: types.REQUEST_ITEMS, payload: {} }],
            [],
          );
        });
      });

      describe('receiveItemsSuccess', () => {
        it('should set `state.itemsFetchInProgress` to false', () => {
          testAction(
            actions.receiveItemsSuccess,
            {},
            {},
            [{ type: types.RECEIVE_ITEMS_SUCCESS, payload: {} }],
            [],
          );
        });
      });

      describe('receiveItemsFailure', () => {
        it('should set `state.itemsFetchInProgress` to false', () => {
          testAction(
            actions.receiveItemsFailure,
            {},
            {},
            [{ type: types.RECEIVE_ITEMS_FAILURE, payload: {} }],
            [],
          );
        });

        it('should show alert error with message "Something went wrong while fetching child epics."', () => {
          const message = 'Something went wrong while fetching child epics.';
          actions.receiveItemsFailure(
            {
              commit: () => {},
            },
            {},
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });
      });

      describe('fetchItems', () => {
        it('should dispatch `requestItems` action', () => {
          testAction(
            actions.fetchItems,
            { parentItem: mockParentItem, isSubItem: false },
            {},
            [],
            [
              {
                type: 'requestItems',
                payload: { parentItem: mockParentItem, isSubItem: false },
              },
            ],
          );
        });

        it('should dispatch `receiveItemsSuccess`, `setItemChildren`, `setItemChildrenFlags`, `setEpicPageInfo` and `setIssuePageInfo` on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
            Promise.resolve({
              data: mockQueryResponse.data,
            }),
          );

          const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

          const {
            children: { pageInfo: epicPageInfo },
            issues: { pageInfo: issuesPageInfo },
            descendantCounts: epicDescendantCounts,
            descendantWeightSum,
            healthStatus,
          } = mockQueryResponse.data.group.epic;

          testAction(
            actions.fetchItems,
            { parentItem: mockParentItem, isSubItem: false },
            {},
            [],
            [
              {
                type: 'requestItems',
                payload: { parentItem: mockParentItem, isSubItem: false },
              },
              {
                type: 'receiveItemsSuccess',
                payload: {
                  parentItem: mockParentItem,
                  isSubItem: false,
                  children,
                },
              },
              {
                type: 'setItemChildren',
                payload: {
                  parentItem: mockParentItem,
                  isSubItem: false,
                  children,
                },
              },
              {
                type: 'setItemChildrenFlags',
                payload: {
                  isSubItem: false,
                  children,
                },
              },
              {
                type: 'setDefaultProjectForIssueCreation',
                payload: mockDefaultProjectForIssueCreation,
              },
              {
                type: 'setEpicPageInfo',
                payload: {
                  parentItem: mockParentItem,
                  pageInfo: epicPageInfo,
                },
              },
              {
                type: 'setIssuePageInfo',
                payload: {
                  parentItem: mockParentItem,
                  pageInfo: issuesPageInfo,
                },
              },
              {
                type: 'setWeightSum',
                payload: descendantWeightSum,
              },
              {
                type: 'setChildrenCount',
                payload: {
                  ...epicDescendantCounts,
                },
              },
              {
                type: 'setHealthStatus',
                payload: {
                  ...healthStatus,
                },
              },
            ],
          );
        });

        it('should not dispatch `setWeightSum`, `setChildrenCount`, `setHealthStatus` when isSubItem is true', () => {
          jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
            Promise.resolve({
              data: mockQueryResponse.data,
            }),
          );

          const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

          const {
            children: { pageInfo: epicPageInfo },
            issues: { pageInfo: issuesPageInfo },
          } = mockQueryResponse.data.group.epic;

          testAction(
            actions.fetchItems,
            { parentItem: mockParentItem, isSubItem: true },
            {},
            [],
            [
              {
                type: 'requestItems',
                payload: { parentItem: mockParentItem, isSubItem: true },
              },
              {
                type: 'receiveItemsSuccess',
                payload: {
                  parentItem: mockParentItem,
                  isSubItem: true,
                  children,
                },
              },
              {
                type: 'setItemChildren',
                payload: {
                  parentItem: mockParentItem,
                  isSubItem: true,
                  children,
                },
              },
              {
                type: 'setItemChildrenFlags',
                payload: {
                  isSubItem: true,
                  children,
                },
              },
              {
                type: 'setDefaultProjectForIssueCreation',
                payload: mockDefaultProjectForIssueCreation,
              },
              {
                type: 'setEpicPageInfo',
                payload: {
                  parentItem: mockParentItem,
                  pageInfo: epicPageInfo,
                },
              },
              {
                type: 'setIssuePageInfo',
                payload: {
                  parentItem: mockParentItem,
                  pageInfo: issuesPageInfo,
                },
              },
            ],
          );
        });

        it('should dispatch `receiveItemsFailure` on request failure', () => {
          jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(Promise.reject());

          testAction(
            actions.fetchItems,
            { parentItem: mockParentItem, isSubItem: false },
            {},
            [],
            [
              {
                type: 'requestItems',
                payload: { parentItem: mockParentItem, isSubItem: false },
              },
              {
                type: 'receiveItemsFailure',
                payload: {
                  parentItem: mockParentItem,
                  isSubItem: false,
                },
              },
            ],
          );
        });
      });

      describe('receiveNextPageItemsFailure', () => {
        it('should show alert error with message "Something went wrong while fetching child epics."', () => {
          const message = 'Something went wrong while fetching child epics.';
          actions.receiveNextPageItemsFailure(
            {
              commit: () => {},
            },
            {},
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });
      });

      describe('fetchNextPageItems', () => {
        it('should dispatch `setItemChildren`, `setItemChildrenFlags`, `setEpicPageInfo` and `setIssuePageInfo` on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(
            Promise.resolve({
              data: mockQueryResponse.data,
            }),
          );

          const epicPageInfo = mockQueryResponse.data.group.epic.children.pageInfo;
          const issuesPageInfo = mockQueryResponse.data.group.epic.issues.pageInfo;

          testAction(
            actions.fetchNextPageItems,
            { parentItem: mockParentItem, isSubItem: false },
            { childrenFlags: { 'gitlab-org&1': {} } },
            [],
            [
              {
                type: 'setItemChildren',
                payload: {
                  parentItem: mockParentItem,
                  isSubItem: false,
                  append: true,
                  children: [],
                },
              },
              {
                type: 'setItemChildrenFlags',
                payload: {
                  isSubItem: false,
                  children: [],
                },
              },
              {
                type: 'setEpicPageInfo',
                payload: {
                  parentItem: mockParentItem,
                  pageInfo: epicPageInfo,
                },
              },
              {
                type: 'setIssuePageInfo',
                payload: {
                  parentItem: mockParentItem,
                  pageInfo: issuesPageInfo,
                },
              },
            ],
          );
        });

        it('should dispatch `receiveNextPageItemsFailure` on request failure', () => {
          jest.spyOn(epicUtils.gqClient, 'query').mockReturnValue(Promise.reject());

          testAction(
            actions.fetchNextPageItems,
            { parentItem: mockParentItem, isSubItem: false },
            { childrenFlags: { 'gitlab-org&1': {} } },
            [],
            [
              {
                type: 'receiveNextPageItemsFailure',
                payload: {
                  parentItem: mockParentItem,
                },
              },
            ],
          );
        });
      });

      describe('toggleItem', () => {
        const data = {
          parentItem: {
            reference: '&1',
          },
        };

        it('should dispatch `fetchItems` when a parent item is not expanded and does not have children present in state', () => {
          state.childrenFlags[data.parentItem.reference] = {
            itemExpanded: false,
          };

          testAction(
            actions.toggleItem,
            data,
            state,
            [],
            [
              {
                type: 'fetchItems',
                payload: { parentItem: data.parentItem, isSubItem: true },
              },
            ],
          );
        });

        it('should dispatch `expandItem` when a parent item is not expanded but does have children present in state', () => {
          state.childrenFlags[data.parentItem.reference] = {
            itemExpanded: false,
          };
          state.children[data.parentItem.reference] = ['foo'];

          testAction(
            actions.toggleItem,
            data,
            state,
            [],
            [
              {
                type: 'expandItem',
                payload: { parentItem: data.parentItem },
              },
            ],
          );
        });

        it('should dispatch `collapseItem` when a parent item is expanded', () => {
          state.childrenFlags[data.parentItem.reference] = {
            itemExpanded: true,
          };

          testAction(
            actions.toggleItem,
            data,
            state,
            [],
            [
              {
                type: 'collapseItem',
                payload: { parentItem: data.parentItem },
              },
            ],
          );
        });
      });

      describe('setRemoveItemModalProps', () => {
        it('should set values on `state.removeItemModalProps` for initializing modal', () => {
          testAction(
            actions.setRemoveItemModalProps,
            {},
            {},
            [{ type: types.SET_REMOVE_ITEM_MODAL_PROPS, payload: {} }],
            [],
          );
        });
      });

      describe('requestRemoveItem', () => {
        it('should set `state.childrenFlags[ref].itemRemoveInProgress` to true', () => {
          testAction(
            actions.requestRemoveItem,
            {},
            {},
            [{ type: types.REQUEST_REMOVE_ITEM, payload: {} }],
            [],
          );
        });
      });

      describe('receiveRemoveItemSuccess', () => {
        it('should set `state.childrenFlags[ref].itemRemoveInProgress` to false', () => {
          testAction(
            actions.receiveRemoveItemSuccess,
            {},
            {},
            [{ type: types.RECEIVE_REMOVE_ITEM_SUCCESS, payload: {} }],
            [],
          );
        });
      });

      describe('receiveRemoveItemFailure', () => {
        it('should set `state.childrenFlags[ref].itemRemoveInProgress` to false', () => {
          testAction(
            actions.receiveRemoveItemFailure,
            { item: { type: ChildType.Epic } },
            {},
            [
              {
                type: types.RECEIVE_REMOVE_ITEM_FAILURE,
                payload: { item: { type: ChildType.Epic } },
              },
            ],
            [],
          );
        });

        it('should show alert error with message "An error occurred while removing epics."', () => {
          actions.receiveRemoveItemFailure(
            {
              commit: () => {},
            },
            {
              item: { type: ChildType.Epic },
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred while removing epics.',
          });
        });
      });

      describe('removeItem', () => {
        let mock;
        const data = {
          parentItem: mockParentItem,
          item: { ...mockParentItem, iid: 2, relationPath: '/foo/bar' },
        };

        beforeEach(() => {
          mock = new MockAdapter(axios);
          state.parentItem = mockParentItem;
        });

        afterEach(() => {
          mock.restore();
        });

        it('should dispatch `requestRemoveItem` and `receiveRemoveItemSuccess` actions on request success', () => {
          mock.onDelete(data.item.relationPath).replyOnce(HTTP_STATUS_OK, {});

          testAction(
            actions.removeItem,
            { ...data },
            state,
            [],
            [
              {
                type: 'requestRemoveItem',
                payload: { item: data.item },
              },
              {
                type: 'receiveRemoveItemSuccess',
                payload: { parentItem: data.parentItem, item: data.item },
              },
              {
                type: 'fetchItems',
                payload: { parentItem: mockParentItem },
              },
            ],
          );
        });

        it('should dispatch `requestRemoveItem` and `receiveRemoveItemFailure` actions on request failure', () => {
          mock.onDelete(data.item.relationPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

          testAction(
            actions.removeItem,
            { ...data },
            state,
            [],
            [
              {
                type: 'requestRemoveItem',
                payload: { item: data.item },
              },
              {
                type: 'receiveRemoveItemFailure',
                payload: { item: data.item, status: undefined },
              },
            ],
          );
        });
      });

      describe('toggleAddItemForm', () => {
        it('should set `state.showAddItemForm` to true', () => {
          testAction(
            actions.toggleAddItemForm,
            {},
            {},
            [{ type: types.TOGGLE_ADD_ITEM_FORM, payload: {} }],
            [],
          );
        });
      });

      describe('toggleCreateEpicForm', () => {
        it('should set `state.showCreateEpicForm` to true', () => {
          testAction(
            actions.toggleCreateEpicForm,
            {},
            {},
            [{ type: types.TOGGLE_CREATE_EPIC_FORM, payload: {} }],
            [],
          );
        });
      });

      describe('toggleCreateIssueForm', () => {
        it('should set `state.showCreateIssueForm` to true and `state.showAddItemForm` to false', () => {
          testAction(
            actions.toggleCreateIssueForm,
            {},
            {},
            [{ type: types.TOGGLE_CREATE_ISSUE_FORM, payload: {} }],
            [],
          );
        });
      });

      describe('setPendingReferences', () => {
        it('should set param value to `state.pendingReference`', () => {
          testAction(
            actions.setPendingReferences,
            {},
            {},
            [{ type: types.SET_PENDING_REFERENCES, payload: {} }],
            [],
          );
        });
      });

      describe('addPendingReferences', () => {
        it('should add param value to `state.pendingReference`', () => {
          testAction(
            actions.addPendingReferences,
            {},
            {},
            [{ type: types.ADD_PENDING_REFERENCES, payload: {} }],
            [],
          );
        });
      });

      describe('removePendingReference', () => {
        it('should remove param value to `state.pendingReference`', () => {
          testAction(
            actions.removePendingReference,
            {},
            {},
            [{ type: types.REMOVE_PENDING_REFERENCE, payload: {} }],
            [],
          );
        });
      });

      describe('setItemInputValue', () => {
        it('should set param value to `state.itemInputValue`', () => {
          testAction(
            actions.setItemInputValue,
            {},
            {},
            [{ type: types.SET_ITEM_INPUT_VALUE, payload: {} }],
            [],
          );
        });
      });

      describe('requestAddItem', () => {
        it('should set `state.itemAddInProgress` to true', () => {
          testAction(actions.requestAddItem, {}, {}, [{ type: types.REQUEST_ADD_ITEM }], []);
        });
      });

      describe('receiveAddItemSuccess', () => {
        it('should set `state.itemAddInProgress` to false and dispatches actions `setPendingReferences`, `setItemInputValue` and `toggleAddItemForm`', () => {
          state.issuableType = TYPE_EPIC;
          state.isEpic = true;

          const mockEpicsWithoutPerm = mockEpics.map((item) => ({
            ...item,
            pathIdSeparator: PathIdSeparator.Epic,
            userPermissions: { canAdmin: undefined },
          }));

          testAction(
            actions.receiveAddItemSuccess,
            { rawItems: mockEpicsWithoutPerm },
            state,
            [
              {
                type: types.RECEIVE_ADD_ITEM_SUCCESS,
                payload: {
                  insertAt: 0,
                  items: mockEpicsWithoutPerm,
                },
              },
            ],
            [
              {
                type: 'setItemChildrenFlags',
                payload: { children: mockEpicsWithoutPerm, isSubItem: false },
              },
              {
                type: 'setPendingReferences',
                payload: [],
              },
              {
                type: 'setItemInputValue',
                payload: '',
              },
              {
                type: 'toggleAddItemForm',
                payload: { toggleState: false },
              },
            ],
          );
        });
      });

      describe('receiveAddItemFailure', () => {
        it('should set `state.itemAddInProgress` to false', () => {
          testAction(
            actions.receiveAddItemFailure,
            {
              itemAddFailureType: itemAddFailureTypesMap.NOT_FOUND,
              itemAddFailureMessage: 'Foobar',
            },
            {},
            [
              {
                type: types.RECEIVE_ADD_ITEM_FAILURE,
                payload: {
                  itemAddFailureType: itemAddFailureTypesMap.NOT_FOUND,
                  itemAddFailureMessage: 'Foobar',
                },
              },
            ],
            [],
          );
        });

        it('should set `state.itemAddInProgress` to false, no payload', () => {
          testAction(
            actions.receiveAddItemFailure,
            undefined,
            {},
            [
              {
                type: types.RECEIVE_ADD_ITEM_FAILURE,
                payload: { itemAddFailureType: undefined, itemAddFailureMessage: '' },
              },
            ],
            [],
          );
        });
      });

      describe('addItem', () => {
        let mock;

        beforeEach(() => {
          mock = new MockAdapter(axios);
          state.parentItem = mockParentItem;
        });

        afterEach(() => {
          mock.restore();
        });

        it('should dispatch `requestAddItem` and `receiveAddItemSuccess` actions on request success', () => {
          state.issuableType = TYPE_EPIC;
          state.epicsEndpoint = '/foo/bar';
          state.pendingReferences = ['foo'];
          state.isEpic = true;

          mock.onPost(state.epicsEndpoint).replyOnce(HTTP_STATUS_OK, { issuables: [mockEpic1] });

          testAction(
            actions.addItem,
            {},
            state,
            [],
            [
              {
                type: 'requestAddItem',
              },
              {
                type: 'receiveAddItemSuccess',
                payload: { rawItems: [mockEpic1] },
              },
              {
                type: 'fetchItems',
                payload: { parentItem: mockParentItem },
              },
            ],
          );
        });

        it('should track Snowplow event', async () => {
          jest.spyOn(Tracking, 'event');
          state.epicsEndpoint = '/foo/bar';
          state.parentItem = { groupId: 1 };

          const getters = {
            isEpic: true,
          };

          mock.onPost(state.epicsEndpoint).replyOnce(HTTP_STATUS_OK, { issuables: [] });

          actions.addItem({ state, dispatch: () => {}, getters });
          await axios.waitForAll();

          expect(Tracking.event).toHaveBeenCalledWith(
            SNOWPLOW_EPIC_ACTIVITY.CATEGORY,
            SNOWPLOW_EPIC_ACTIVITY.ACTION,
            {
              label: SNOWPLOW_EPIC_ACTIVITY.LABEL,
              property: trackingAddedIssue,
              namespace: 1,
            },
          );
        });

        it('should dispatch `requestAddItem` and `receiveAddItemFailure` actions on request failure', () => {
          state.issuableType = TYPE_EPIC;
          state.epicsEndpoint = '/foo/bar';
          state.pendingReferences = ['foo'];

          mock.onPost(state.epicsEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

          testAction(
            actions.addItem,
            {},
            state,
            [],
            [
              {
                type: 'requestAddItem',
              },
              {
                type: 'receiveAddItemFailure',
                payload: {
                  itemAddFailureType: itemAddFailureTypesMap.NOT_FOUND,
                },
              },
            ],
          );
        });
      });

      describe('requestCreateItem', () => {
        it('should set `state.itemCreateInProgress` to true', () => {
          testAction(actions.requestCreateItem, {}, {}, [{ type: types.REQUEST_CREATE_ITEM }], []);
        });
      });

      describe('receiveCreateItemSuccess', () => {
        it('should set `state.itemCreateInProgress` to false', () => {
          const createdEpic = {
            ...mockEpics[0],
            id: `gid://gitlab/Epic/${mockEpics[0].id}`,
            reference: `${mockEpics[0].group.fullPath}${mockEpics[0].reference}`,
            pathIdSeparator: PathIdSeparator.Epic,
          };
          state.parentItem = {
            fullPath: createdEpic.group.fullPath,
          };
          state.issuableType = TYPE_EPIC;
          state.isEpic = true;

          testAction(
            actions.receiveCreateItemSuccess,
            { rawItem: mockEpic1 },
            state,
            [
              {
                type: types.RECEIVE_CREATE_ITEM_SUCCESS,
                payload: { insertAt: 0, item: createdEpic },
              },
            ],
            [
              {
                type: 'updateChildrenCount',
                payload: { item: createdEpic },
              },
              {
                type: 'setItemChildrenFlags',
                payload: { children: [createdEpic], isSubItem: false },
              },
              {
                type: 'toggleCreateEpicForm',
                payload: { toggleState: false },
              },
            ],
          );
        });
      });

      describe('receiveCreateItemFailure', () => {
        it('should set `state.itemCreateInProgress` to false', () => {
          testAction(
            actions.receiveCreateItemFailure,
            {},
            {},
            [{ type: types.RECEIVE_CREATE_ITEM_FAILURE }],
            [],
          );
        });

        it('should show alert error with message from API', () => {
          const message = 'Error message from API';
          actions.receiveCreateItemFailure(
            {
              commit: () => {},
              state: {},
            },
            {
              message,
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });

        it('should show alert error without message from API', () => {
          actions.receiveCreateItemFailure(
            {
              commit: () => {},
              state: {},
            },
            {
              message: undefined,
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message: EPIC_CREATE_ERROR_MESSAGE,
          });
        });
      });

      describe('createItem', () => {
        let mock;

        beforeEach(() => {
          mock = new MockAdapter(axios);
          state.parentItem = mockParentItem;
          state.issuableType = TYPE_EPIC;
        });

        afterEach(() => {
          mock.restore();
        });

        it('should dispatch `requestCreateItem` and `receiveCreateItemSuccess` actions on request success', () => {
          mock.onPost(/(.*)/).replyOnce(HTTP_STATUS_OK, mockEpic1);

          return testAction(
            actions.createItem,
            { itemTitle: 'Sample child epic' },
            state,
            [],
            [
              {
                type: 'requestCreateItem',
              },
              {
                type: 'receiveCreateItemSuccess',
                payload: {
                  rawItem: { ...mockEpic1, path: '', state: STATUS_OPEN, created_at: '' },
                },
              },
              {
                type: 'fetchItems',
                payload: {
                  parentItem: {
                    ...mockParentItem,
                  },
                },
              },
            ],
          );
        });

        it('should dispatch `requestCreateItem` and `receiveCreateItemFailure` actions on request failure', () => {
          mock.onPost(/(.*)/).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

          return testAction(
            actions.createItem,
            { itemTitle: 'Sample child epic' },
            state,
            [],
            [
              {
                type: 'requestCreateItem',
              },
              {
                type: 'receiveCreateItemFailure',
                payload: {
                  message: undefined,
                },
              },
            ],
          );
        });
      });

      describe('receiveReorderItemFailure', () => {
        it('should revert reordered item back to its original position via REORDER_ITEM mutation', () => {
          return testAction(
            actions.receiveReorderItemFailure,
            {},
            {},
            [{ type: types.REORDER_ITEM, payload: {} }],
            [],
          );
        });

        it('should show alert error with message "Something went wrong while ordering item."', () => {
          const message = 'Something went wrong while ordering item.';
          actions.receiveReorderItemFailure(
            {
              commit: () => {},
            },
            {
              message,
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });
      });

      describe('reorderItem', () => {
        it('should perform REORDER_ITEM mutation before request and do nothing on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(
            Promise.resolve({
              data: mockReorderMutationResponse,
            }),
          );

          return testAction(
            actions.reorderItem,
            {
              treeReorderMutation: mockEpicTreeReorderInput.moved,
              parentItem: mockParentItem,
              targetItem: mockItems[1],
              oldIndex: 1,
              newIndex: 0,
            },
            {},
            [
              {
                type: types.REORDER_ITEM,
                payload: {
                  parentItem: mockParentItem,
                  targetItem: mockItems[1],
                  oldIndex: 1,
                  newIndex: 0,
                },
              },
            ],
            [],
          );
        });

        it('should perform REORDER_ITEM mutation before request and dispatch `receiveReorderItemFailure` when request response has errors on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(
            Promise.resolve({
              data: {
                epicTreeReorder: {
                  ...mockReorderMutationResponse.epicTreeReorder,
                  errors: [{ foo: 'bar' }],
                },
              },
            }),
          );

          return testAction(
            actions.reorderItem,
            {
              treeReorderMutation: mockEpicTreeReorderInput.moved,
              parentItem: mockParentItem,
              targetItem: mockItems[1],
              oldIndex: 1,
              newIndex: 0,
            },
            {},
            [
              {
                type: types.REORDER_ITEM,
                payload: {
                  parentItem: mockParentItem,
                  targetItem: mockItems[1],
                  oldIndex: 1,
                  newIndex: 0,
                },
              },
            ],
            [
              {
                type: 'receiveReorderItemFailure',
                payload: {
                  parentItem: mockParentItem,
                  targetItem: mockItems[1],
                  oldIndex: 0,
                  newIndex: 1,
                },
              },
            ],
          );
        });

        it('should perform REORDER_ITEM mutation before request and dispatch `receiveReorderItemFailure` on request failure', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(Promise.reject());

          return testAction(
            actions.reorderItem,
            {
              treeReorderMutation: mockEpicTreeReorderInput.moved,
              parentItem: mockParentItem,
              targetItem: mockItems[1],
              oldIndex: 1,
              newIndex: 0,
            },
            {},
            [
              {
                type: types.REORDER_ITEM,
                payload: {
                  parentItem: mockParentItem,
                  targetItem: mockItems[1],
                  oldIndex: 1,
                  newIndex: 0,
                },
              },
            ],
            [
              {
                type: 'receiveReorderItemFailure',
                payload: {
                  parentItem: mockParentItem,
                  targetItem: mockItems[1],
                  oldIndex: 0,
                  newIndex: 1,
                },
              },
            ],
          );
        });
      });

      describe('receiveMoveItemFailure', () => {
        it('should revert moved item back to its original position on its original parent via MOVE_ITEM_FAILURE mutation', () => {
          return testAction(
            actions.receiveMoveItemFailure,
            {},
            {},
            [{ type: types.MOVE_ITEM_FAILURE, payload: {} }],
            [],
          );
        });

        it('should show alert error with message "Something went wrong while ordering item."', () => {
          const message = 'Something went wrong while moving item.';
          actions.receiveMoveItemFailure(
            {
              commit: () => {},
            },
            {
              message,
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });
      });

      describe('moveItem', () => {
        beforeAll(() => {
          state.children[mockParentItem2.parentReference] = [];
        });

        it('should perform MOVE_ITEM mutation with isFirstChild to true if parent has no children before request and do nothing on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(
            Promise.resolve({
              data: mockReorderMutationResponse,
            }),
          );

          return testAction(
            actions.moveItem,
            {
              oldParentItem: mockParentItem,
              newParentItem: mockParentItem2,
              targetItem: mockItems[1],
              newIndex: 1,
              oldIndex: 0,
            },
            state,
            [
              {
                type: types.MOVE_ITEM,
                payload: {
                  oldParentItem: mockParentItem,
                  newParentItem: mockParentItem2,
                  targetItem: mockItems[1],
                  newIndex: 1,
                  oldIndex: 0,
                  isFirstChild: true,
                },
              },
            ],
            [],
          );
        });

        it('should perform MOVE_ITEM mutation with isFirstChild to false if parent has children before request and do nothing on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(
            Promise.resolve({
              data: mockReorderMutationResponse,
            }),
          );

          state.children[mockParentItem2.parentReference] = [{ id: '33' }];

          return testAction(
            actions.moveItem,
            {
              oldParentItem: mockParentItem,
              newParentItem: mockParentItem2,
              targetItem: mockItems[1],
              newIndex: 1,
              oldIndex: 0,
            },
            state,
            [
              {
                type: types.MOVE_ITEM,
                payload: {
                  oldParentItem: mockParentItem,
                  newParentItem: mockParentItem2,
                  targetItem: mockItems[1],
                  newIndex: 1,
                  oldIndex: 0,
                  isFirstChild: false,
                },
              },
            ],
            [],
          );
        });

        it('should perform MOVE_ITEM mutation before request and dispatch `receiveReorderItemFailure` when request response has errors on request success', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(
            Promise.resolve({
              data: {
                epicTreeReorder: {
                  ...mockReorderMutationResponse.epicTreeReorder,
                  errors: [{ foo: 'bar' }],
                },
              },
            }),
          );

          const payload = {
            oldParentItem: mockParentItem,
            newParentItem: mockParentItem2,
            targetItem: mockItems[1],
            newIndex: 1,
            oldIndex: 0,
          };

          return testAction(
            actions.moveItem,
            payload,
            state,
            [
              {
                type: types.MOVE_ITEM,
                payload: {
                  oldParentItem: mockParentItem,
                  newParentItem: mockParentItem2,
                  targetItem: mockItems[1],
                  newIndex: 1,
                  oldIndex: 0,
                  isFirstChild: true,
                },
              },
            ],
            [
              {
                type: 'receiveMoveItemFailure',
                payload,
              },
            ],
          );
        });

        it('should perform MOVE_ITEM mutation before request and dispatch `receiveReorderItemFailure` on request failure', () => {
          jest.spyOn(epicUtils.gqClient, 'mutate').mockReturnValue(Promise.reject());

          const payload = {
            oldParentItem: mockParentItem,
            newParentItem: mockParentItem2,
            targetItem: mockItems[1],
            newIndex: 1,
            oldIndex: 0,
          };

          testAction(
            actions.moveItem,
            payload,
            state,
            [
              {
                type: types.MOVE_ITEM,
                payload: {
                  oldParentItem: mockParentItem,
                  newParentItem: mockParentItem2,
                  targetItem: mockItems[1],
                  newIndex: 1,
                  oldIndex: 0,
                  isFirstChild: true,
                },
              },
            ],
            [
              {
                type: 'receiveMoveItemFailure',
                payload,
              },
            ],
          );
        });
      });

      describe('receiveCreateIssueSuccess', () => {
        it('should set `state.itemCreateInProgress` & `state.itemsFetchResultEmpty` to false', () => {
          return testAction(
            actions.receiveCreateIssueSuccess,
            { insertAt: 0, items: [] },
            {},
            [{ type: types.RECEIVE_CREATE_ITEM_SUCCESS, payload: { insertAt: 0, items: [] } }],
            [],
          );
        });
      });

      describe('receiveCreateIssueFailure', () => {
        it('should set `state.itemCreateInProgress` to false', () => {
          return testAction(
            actions.receiveCreateIssueFailure,
            {},
            {},
            [{ type: types.RECEIVE_CREATE_ITEM_FAILURE }],
            [],
          );
        });

        it('should show alert error with message "Something went wrong while creating issue."', () => {
          const message = 'Something went wrong while creating issue.';
          actions.receiveCreateIssueFailure(
            {
              commit: () => {},
            },
            {
              message,
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });
      });

      describe('createNewIssue', () => {
        const issuesEndpoint = `${TEST_HOST}/issues`;
        const title = 'new issue title';
        const epicId = 42;
        const parentItem = {
          id: `gid://gitlab/Epic/${epicId}`,
        };
        const expectedRequest = expect.objectContaining({
          data: JSON.stringify({
            epic_id: epicId,
            title,
          }),
        });

        let axiosMock;
        let requestSpy;
        let context;
        let payload;

        beforeEach(() => {
          axiosMock = new MockAdapter(axios);
        });

        afterEach(() => {
          axiosMock.restore();
        });

        beforeEach(() => {
          requestSpy = jest.fn();
          axiosMock.onPost(issuesEndpoint).replyOnce((config) => requestSpy(config));

          context = {
            state: {
              parentItem,
            },
            dispatch: jest.fn(),
          };

          payload = {
            issuesEndpoint,
            title,
          };
        });

        describe('for successful request', () => {
          it('should track Snowplow event', async () => {
            jest.spyOn(Tracking, 'event');
            state.parentItem = { id: '1' };
            const data = { author: { id: 1 }, epic: { group_id: 2 } };

            axiosMock.reset();
            axiosMock.onPost(issuesEndpoint).replyOnce(HTTP_STATUS_OK, data);

            actions.createNewIssue({ state, dispatch: () => {} }, { issuesEndpoint, title: '' });
            await axios.waitForAll();

            expect(Tracking.event).toHaveBeenCalledWith(
              SNOWPLOW_EPIC_ACTIVITY.CATEGORY,
              SNOWPLOW_EPIC_ACTIVITY.ACTION,
              {
                label: SNOWPLOW_EPIC_ACTIVITY.LABEL,
                property: trackingAddedIssue,
                namespace: 2,
                user: 1,
              },
            );
          });

          beforeEach(() => {
            requestSpy.mockReturnValue([201, '']);
          });

          it('dispatches fetchItems', () => {
            return actions.createNewIssue(context, payload).then(() => {
              expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
              expect(context.dispatch).toHaveBeenCalledWith('requestCreateItem');
              expect(context.dispatch).toHaveBeenCalledWith('receiveCreateIssueSuccess', '');
              expect(context.dispatch).toHaveBeenCalledWith(
                'fetchItems',
                expect.objectContaining({ parentItem }),
              );

              expect(createAlert).not.toHaveBeenCalled();
            });
          });
        });

        describe('for failed request', () => {
          beforeEach(() => {
            requestSpy.mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR, '']);
          });

          it('fails and shows alert message', async () => {
            await expect(actions.createNewIssue(context, payload)).rejects.toEqual(
              new Error('Request failed with status code 500'),
            );
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
            expect(context.dispatch).toHaveBeenCalledWith('receiveCreateIssueFailure');
          });
        });
      });

      describe('requestProjects', () => {
        it('should set `state.projectsFetchInProgress` to true', () => {
          return testAction(
            actions.requestProjects,
            {},
            {},
            [{ type: types.REQUEST_PROJECTS }],
            [],
          );
        });
      });

      describe('receiveProjectsSuccess', () => {
        it('should set `state.projectsFetchInProgress` to false and set provided `projects` param to state', () => {
          return testAction(
            actions.receiveProjectsSuccess,
            mockProjects,
            {},
            [{ type: types.RECEIVE_PROJECTS_SUCCESS, payload: mockProjects }],
            [],
          );
        });
      });

      describe('receiveProjectsFailure', () => {
        it('should set `state.projectsFetchInProgress` to false', () => {
          return testAction(
            actions.receiveProjectsFailure,
            {},
            {},
            [{ type: types.RECEIVE_PROJECTS_FAILURE }],
            [],
          );
        });

        it('should show alert error with message "Something went wrong while fetching projects."', () => {
          const message = 'Something went wrong while fetching projects.';
          actions.receiveProjectsFailure(
            {
              commit: () => {},
            },
            {
              message,
            },
          );

          expect(createAlert).toHaveBeenCalledWith({
            message,
          });
        });
      });

      describe('fetchProjects', () => {
        let mock;

        beforeEach(() => {
          mock = new MockAdapter(axios);
          state.parentItem = mockParentItem;
          state.issuableType = TYPE_EPIC;
        });

        afterEach(() => {
          mock.restore();
        });

        it('should dispatch `requestProjects` and `receiveProjectsSuccess` actions on request success', () => {
          mock.onGet(/(.*)/).replyOnce(HTTP_STATUS_OK, mockProjects);

          return testAction(
            actions.fetchProjects,
            '',
            state,
            [],
            [
              {
                type: 'requestProjects',
              },
              {
                type: 'receiveProjectsSuccess',
                payload: mockProjects,
              },
            ],
          );
        });

        it('should dispatch `requestProjects` and `receiveProjectsFailure` actions on request failure', () => {
          mock.onGet(/(.*)/).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

          return testAction(
            actions.fetchProjects,
            '',
            state,
            [],
            [
              {
                type: 'requestProjects',
              },
              {
                type: 'receiveProjectsFailure',
              },
            ],
          );
        });
      });

      describe('setDefaultProjectForIssueCreation', () => {
        it('should set defaultProjectForIssueCreation on state', () => {
          testAction(
            actions.setDefaultProjectForIssueCreation,
            mockDefaultProjectForIssueCreation,
            {},
            [
              {
                type: types.SET_DEFAULT_PROJECT_FOR_ISSUE_CREATION,
                payload: mockDefaultProjectForIssueCreation,
              },
            ],
            [],
          );
        });
      });
    });
  });
});
