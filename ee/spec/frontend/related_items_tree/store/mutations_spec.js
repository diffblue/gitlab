import * as types from 'ee/related_items_tree/store/mutation_types';
import mutations from 'ee/related_items_tree/store/mutations';
import createDefaultState from 'ee/related_items_tree/store/state';

describe('RelatedItemsTree', () => {
  describe('store', () => {
    describe('mutations', () => {
      let state;

      beforeEach(() => {
        state = createDefaultState();
      });

      describe(types.SET_INITIAL_CONFIG, () => {
        it('should set provided `data` param props to state', () => {
          const data = {
            epicsEndpoint: '/foo',
            issuesEndpoint: '/bar',
            autoCompleteEpics: true,
            autoCompleteIssues: false,
            allowSubEpics: true,
            allowIssuableHealthStatus: true,
          };

          mutations[types.SET_INITIAL_CONFIG](state, data);

          expect(state).toHaveProperty('epicsEndpoint', '/foo');
          expect(state).toHaveProperty('issuesEndpoint', '/bar');
          expect(state).toHaveProperty('autoCompleteEpics', true);
          expect(state).toHaveProperty('autoCompleteIssues', false);
          expect(state).toHaveProperty('allowSubEpics', true);
          expect(state).toHaveProperty('allowIssuableHealthStatus', true);
          expect(state).toHaveProperty('healthStatus', {
            issuesNeedingAttention: 0,
            issuesAtRisk: 0,
            issuesOnTrack: 0,
          });
          expect(state).toHaveProperty('weightSum', {
            openedIssues: 0,
            closedIssues: 0,
          });
        });
      });

      describe(types.SET_INITIAL_PARENT_ITEM, () => {
        it('should set provided `data` param props to state.parentItem', () => {
          const data = {
            foo: 'bar',
            bar: 'baz',
            reference: '&1',
          };

          mutations[types.SET_INITIAL_PARENT_ITEM](state, data);

          expect(state.parentItem).toHaveProperty('foo', 'bar');
          expect(state.parentItem).toHaveProperty('bar', 'baz');
          expect(state.childrenFlags[data.reference]).toBeDefined();
        });
      });

      describe(types.SET_CHILDREN_COUNT, () => {
        it('should set provided `epicsCount` and `issuesCount` to state', () => {
          const data = {
            openedEpics: 4,
            closedEpics: 5,
            openedIssues: 6,
            closedIssues: 7,
          };

          mutations[types.SET_CHILDREN_COUNT](state, data);

          expect(state.descendantCounts).toEqual(data);
        });
      });

      describe(types.SET_ITEM_CHILDREN, () => {
        const data = {
          parentItem: { reference: '&1' },
          children: [
            {
              reference: 'frontend&1',
            },
            {
              reference: 'frontend&2',
            },
          ],
        };

        it('should set provided children to parent in the state', () => {
          mutations[types.SET_ITEM_CHILDREN](state, data);

          expect(state.children[data.parentItem.reference]).toEqual(
            expect.arrayContaining(data.children),
          );
        });

        it('should append provided children to parent in the state when `append` param is `true`', () => {
          mutations[types.SET_ITEM_CHILDREN](state, data);
          data.append = true;
          mutations[types.SET_ITEM_CHILDREN](state, data);

          expect(state.children[data.parentItem.reference]).toHaveLength(4);
        });
      });

      describe(types.SET_ITEM_CHILDREN_FLAGS, () => {
        it('should set flags in `state.childrenFlags` for each item in `data.children`', () => {
          const data = {
            children: [
              {
                reference: '&1',
                hasChildren: true,
                hasIssues: false,
              },
              {
                reference: '&2',
                hasChildren: false,
                hasIssues: true,
              },
            ],
          };

          mutations[types.SET_ITEM_CHILDREN_FLAGS](state, data);

          data.children.forEach((item) => {
            expect(state.childrenFlags[item.reference]).toEqual(
              expect.objectContaining({
                itemExpanded: false,
                itemChildrenFetchInProgress: false,
                itemRemoveInProgress: false,
                itemHasChildren: true,
              }),
            );
          });
        });
      });

      describe(types.SET_EPIC_PAGE_INFO, () => {
        it('should set `epicEndCursor` and `hasMoreEpics` to `state.childrenFlags`', () => {
          const data = {
            parentItem: { reference: '&1' },
            pageInfo: {
              endCursor: 'abc',
              hasNextPage: true,
            },
          };
          state.childrenFlags[data.parentItem.reference] = {};

          mutations[types.SET_EPIC_PAGE_INFO](state, data);

          expect(state.childrenFlags[data.parentItem.reference].epicEndCursor).toEqual(
            data.pageInfo.endCursor,
          );
          expect(state.childrenFlags[data.parentItem.reference].hasMoreEpics).toEqual(
            data.pageInfo.hasNextPage,
          );
        });
      });

      describe(types.SET_ISSUE_PAGE_INFO, () => {
        it('should set `issueEndCursor` and `hasMoreIssues` to `state.childrenFlags`', () => {
          const data = {
            parentItem: { reference: '&1' },
            pageInfo: {
              endCursor: 'abc',
              hasNextPage: true,
            },
          };
          state.childrenFlags[data.parentItem.reference] = {};

          mutations[types.SET_ISSUE_PAGE_INFO](state, data);

          expect(state.childrenFlags[data.parentItem.reference].issueEndCursor).toEqual(
            data.pageInfo.endCursor,
          );
          expect(state.childrenFlags[data.parentItem.reference].hasMoreIssues).toEqual(
            data.pageInfo.hasNextPage,
          );
        });
      });

      describe(types.REQUEST_ITEMS, () => {
        const data = {
          parentItem: {
            reference: '&1',
          },
        };

        it('should set `itemChildrenFetchInProgress` to true for provided `parentItem` param within state.childrenFlags when `isSubItem` param is true', () => {
          data.isSubItem = true;
          state.childrenFlags[data.parentItem.reference] = {};
          mutations[types.REQUEST_ITEMS](state, data);

          expect(state.childrenFlags[data.parentItem.reference]).toHaveProperty(
            'itemChildrenFetchInProgress',
            true,
          );
        });

        it('should set `state.itemsFetchInProgress` to true when `isSubItem` param is false', () => {
          data.isSubItem = false;
          mutations[types.REQUEST_ITEMS](state, data);

          expect(state.itemsFetchInProgress).toBe(true);
        });
      });

      describe(types.RECEIVE_ITEMS_SUCCESS, () => {
        const data = {
          parentItem: {
            reference: '&1',
          },
        };

        it('should set `itemChildrenFetchInProgress` to false for provided `parentItem` param within state.childrenFlags when `isSubItem` param is true', () => {
          data.isSubItem = true;
          state.childrenFlags[data.parentItem.reference] = {};
          mutations[types.RECEIVE_ITEMS_SUCCESS](state, data);

          expect(state.childrenFlags[data.parentItem.reference]).toHaveProperty(
            'itemChildrenFetchInProgress',
            false,
          );
        });

        it('should set `state.itemsFetchInProgress` to false and `state.itemsFetchResultEmpty` based on provided children param count when `isSubItem` param is false', () => {
          data.isSubItem = false;
          data.children = [];
          mutations[types.RECEIVE_ITEMS_SUCCESS](state, data);

          expect(state.itemsFetchInProgress).toBe(false);
          expect(state.itemsFetchResultEmpty).toBe(true);
        });
      });

      describe(types.RECEIVE_ITEMS_FAILURE, () => {
        const data = {
          parentItem: {
            reference: '&1',
          },
        };

        it('should set `itemChildrenFetchInProgress` to false for provided `parentItem` param within state.childrenFlags when `isSubItem` param is true', () => {
          data.isSubItem = true;
          state.childrenFlags[data.parentItem.reference] = {};
          mutations[types.RECEIVE_ITEMS_FAILURE](state, data);

          expect(state.childrenFlags[data.parentItem.reference]).toHaveProperty(
            'itemChildrenFetchInProgress',
            false,
          );
        });

        it('should set `state.itemsFetchInProgress` to false and `state.itemsFetchResultEmpty` based on provided children param count when `isSubItem` param is false', () => {
          data.isSubItem = false;
          mutations[types.RECEIVE_ITEMS_FAILURE](state, data);

          expect(state.itemsFetchInProgress).toBe(false);
        });
      });

      describe(types.EXPAND_ITEM, () => {
        const data = {
          parentItem: {
            reference: '&1',
          },
        };

        it('should set `itemExpanded` to true for provided `parentItem` param within state.childrenFlags', () => {
          state.childrenFlags[data.parentItem.reference] = {};
          mutations[types.EXPAND_ITEM](state, data);

          expect(state.childrenFlags[data.parentItem.reference]).toHaveProperty(
            'itemExpanded',
            true,
          );
        });
      });

      describe(types.COLLAPSE_ITEM, () => {
        const data = {
          parentItem: {
            reference: '&1',
          },
        };

        it('should set `itemExpanded` to false for provided `parentItem` param within state.childrenFlags', () => {
          state.childrenFlags[data.parentItem.reference] = {};
          mutations[types.COLLAPSE_ITEM](state, data);

          expect(state.childrenFlags[data.parentItem.reference]).toHaveProperty(
            'itemExpanded',
            false,
          );
        });
      });

      describe(types.SET_REMOVE_ITEM_MODAL_PROPS, () => {
        it('should set `parentItem` & `item` to state.removeItemModalProps', () => {
          const data = {
            parentItem: 'foo',
            item: 'bar',
          };

          mutations[types.SET_REMOVE_ITEM_MODAL_PROPS](state, data);

          expect(state.removeItemModalProps).toEqual(
            expect.objectContaining({
              parentItem: data.parentItem,
              item: data.item,
            }),
          );
        });
      });

      describe(types.REQUEST_REMOVE_ITEM, () => {
        it('should set `itemRemoveInProgress` to true for provided `item` param within state.childrenFlags', () => {
          const data = {
            item: {
              reference: '&1',
            },
          };
          state.childrenFlags[data.item.reference] = {};

          mutations[types.REQUEST_REMOVE_ITEM](state, data);

          expect(state.childrenFlags[data.item.reference]).toHaveProperty(
            'itemRemoveInProgress',
            true,
          );
        });
      });

      describe(types.RECEIVE_REMOVE_ITEM_SUCCESS, () => {
        const data = {
          parentItem: {
            reference: 'gitlab-org&1',
          },
          item: {
            reference: '&2',
          },
        };

        it('should set `itemRemoveInProgress` to false for provided `item` param within state.childrenFlags and removes children for provided `parentItem`', () => {
          state.children[data.parentItem.reference] = [data.item];
          state.childrenFlags[data.item.reference] = {};
          state.childrenFlags[data.parentItem.reference] = {};

          mutations[types.RECEIVE_REMOVE_ITEM_SUCCESS](state, data);

          expect(state.childrenFlags[data.item.reference]).toHaveProperty(
            'itemRemoveInProgress',
            false,
          );

          expect(state.children[data.parentItem.reference]).toEqual(expect.arrayContaining([]));
          expect(state.childrenFlags[data.parentItem.reference].itemHasChildren).toBe(false);
        });
      });

      describe(types.RECEIVE_REMOVE_ITEM_FAILURE, () => {
        it('should set `itemRemoveInProgress` to false for provided `item` param within state.childrenFlags', () => {
          const data = {
            item: {
              reference: '&1',
            },
          };
          state.childrenFlags[data.item.reference] = {};

          mutations[types.RECEIVE_REMOVE_ITEM_FAILURE](state, data);

          expect(state.childrenFlags[data.item.reference]).toHaveProperty(
            'itemRemoveInProgress',
            false,
          );
        });
      });

      describe(types.TOGGLE_ADD_ITEM_FORM, () => {
        it('should set value of `issuableType`, `showAddItemForm` as it is and `showCreateEpicForm` as false on state', () => {
          const data = {
            issuableType: 'Epic',
            toggleState: true,
          };

          mutations[types.TOGGLE_ADD_ITEM_FORM](state, data);

          expect(state.issuableType).toBe(data.issuableType);
          expect(state.showAddItemForm).toBe(data.toggleState);
          expect(state.showCreateEpicForm).toBe(false);
        });
      });

      describe(types.TOGGLE_CREATE_EPIC_FORM, () => {
        it('should set value of `showCreateEpicForm` as it is and `showAddItemForm` as false on state', () => {
          const data = { toggleState: true };

          mutations[types.TOGGLE_CREATE_EPIC_FORM](state, data);

          expect(state.showCreateEpicForm).toBe(data.toggleState);
          expect(state.showAddItemForm).toBe(false);
          expect(state.issuableType).toEqual('epic');
        });
      });

      describe(types.TOGGLE_CREATE_ISSUE_FORM, () => {
        it('should set value of `showCreateIssueForm` as it is and `showAddItemForm` as false on state', () => {
          const data = { toggleState: true };

          mutations[types.TOGGLE_CREATE_ISSUE_FORM](state, data);

          expect(state.showCreateIssueForm).toBe(data.toggleState);
          expect(state.showAddItemForm).toBe(false);
        });
      });

      describe(types.SET_PENDING_REFERENCES, () => {
        it('should set `pendingReferences` to state based on provided `references` param', () => {
          const reference = ['foo'];

          mutations[types.SET_PENDING_REFERENCES](state, reference);

          expect(state.pendingReferences).toEqual(expect.arrayContaining(reference));
        });
      });

      describe(types.ADD_PENDING_REFERENCES, () => {
        it('should add value of provided `references` param to `pendingReferences` within state', () => {
          const reference = ['bar'];
          state.pendingReferences = ['foo'];

          mutations[types.ADD_PENDING_REFERENCES](state, reference);

          expect(state.pendingReferences).toEqual(
            expect.arrayContaining(['foo'].concat(reference)),
          );
        });

        it('should not add duplicated `references` param to `pendingReferences` within state', () => {
          const references = ['foo', 'bar'];

          state.pendingReferences = ['foo'];

          mutations[types.ADD_PENDING_REFERENCES](state, references);

          expect(state.pendingReferences).toEqual(['foo', 'bar']);
        });
      });

      describe(types.REMOVE_PENDING_REFERENCE, () => {
        it('should remove value from `pendingReferences` based on provided `indexToRemove` param', () => {
          state.pendingReferences = ['foo', 'bar'];

          mutations[types.REMOVE_PENDING_REFERENCE](state, 1);

          expect(state.pendingReferences).toEqual(expect.arrayContaining(['foo']));
        });

        it('should update `itemAddFailure` to false if no `pendingReferences` are left', () => {
          state.pendingReferences = ['foo'];
          state.itemAddFailure = true;

          mutations[types.REMOVE_PENDING_REFERENCE](state, 0);

          expect(state.pendingReferences).toHaveLength(0);
          expect(state.itemAddFailure).toBe(false);
        });
      });

      describe(types.SET_ITEM_INPUT_VALUE, () => {
        it('should set value of provided `itemInputValue` param to `itemInputValue` within state', () => {
          mutations[types.SET_ITEM_INPUT_VALUE](state, 'foo');

          expect(state.itemInputValue).toBe('foo');
        });
      });

      describe(types.REQUEST_ADD_ITEM, () => {
        it('should set `itemAddInProgress` to true within state', () => {
          mutations[types.REQUEST_ADD_ITEM](state);

          expect(state.itemAddInProgress).toBe(true);
        });
      });

      describe(types.RECEIVE_ADD_ITEM_SUCCESS, () => {
        it('should add provided `items` param to `state.children` and `itemAddInProgress` to false', () => {
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['foo', 'baz'];

          mutations[types.RECEIVE_ADD_ITEM_SUCCESS](state, {
            insertAt: 1,
            items: ['bar'],
          });

          expect(state.children[state.parentItem.reference]).toEqual(
            expect.arrayContaining(['foo', 'bar', 'baz']),
          );
          expect(state.itemAddInProgress).toBe(false);
          expect(state.itemsFetchResultEmpty).toBe(false);
        });
      });

      describe(types.RECEIVE_ADD_ITEM_FAILURE, () => {
        it('should set `itemAddInProgress` to false, `itemAddFailure` to true and `itemAddFailureType` value within state', () => {
          mutations[types.RECEIVE_ADD_ITEM_FAILURE](state, {
            itemAddFailureMessage: 'foo',
            itemAddFailureType: 'bar',
          });

          expect(state.itemAddInProgress).toBe(false);
          expect(state.itemAddFailure).toBe(true);
          expect(state.itemAddFailureMessage).toEqual('foo');
          expect(state.itemAddFailureType).toEqual('bar');
        });
      });

      describe(types.REQUEST_CREATE_ITEM, () => {
        it('should set `itemCreateInProgress` to true within state', () => {
          mutations[types.REQUEST_CREATE_ITEM](state);

          expect(state.itemCreateInProgress).toBe(true);
        });
      });

      describe(types.RECEIVE_CREATE_ITEM_SUCCESS, () => {
        it('should add provided `item` param to `state.children` and `itemCreateInProgress` to false', () => {
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['foo', 'baz'];

          mutations[types.RECEIVE_CREATE_ITEM_SUCCESS](state, {
            insertAt: 1,
            item: 'bar',
          });

          expect(state.children[state.parentItem.reference]).toEqual(
            expect.arrayContaining(['foo', 'bar', 'baz']),
          );
          expect(state.itemCreateInProgress).toBe(false);
          expect(state.itemsFetchResultEmpty).toBe(false);
        });
      });

      describe(types.RECEIVE_CREATE_ITEM_FAILURE, () => {
        it('should set `itemCreateInProgress` to false within state', () => {
          mutations[types.RECEIVE_CREATE_ITEM_FAILURE](state);

          expect(state.itemCreateInProgress).toBe(false);
        });
      });

      describe(types.REORDER_ITEM, () => {
        it('should reorder an item within children of provided parent based on provided indexes', () => {
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['foo', 'bar'];

          mutations[types.REORDER_ITEM](state, {
            parentItem: {
              reference: '&1',
            },
            targetItem: 'bar',
            oldIndex: 1,
            newIndex: 0,
          });

          expect(state.children[state.parentItem.reference]).toEqual(
            expect.arrayContaining(['bar', 'foo']),
          );
        });
      });

      describe(types.MOVE_ITEM, () => {
        const defaultPayload = {
          oldParentItem: {
            reference: '&1',
          },
          targetItem: 'bar',
          oldIndex: 1,
          newIndex: 0,
          isFirstChild: false,
        };

        it('should move an item from one parent to another with children based on provided indexes', () => {
          const newParentItem = {
            parentReference: '&2',
          };
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['foo', 'bar'];
          state.children[newParentItem.parentReference] = ['baz'];

          mutations[types.MOVE_ITEM](state, {
            ...defaultPayload,
            newParentItem,
          });

          expect(state.children[state.parentItem.reference]).toEqual(
            expect.arrayContaining(['foo']),
          );
          expect(state.children[newParentItem.parentReference]).toEqual(
            expect.arrayContaining(['bar', 'baz']),
          );
        });

        it('should move an item from one parent to another without children based on provided indexes', () => {
          const newParentItem = {
            parentReference: '&2',
          };
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['foo', 'bar'];

          mutations[types.MOVE_ITEM](state, {
            ...defaultPayload,
            newParentItem,
            isFirstChild: true,
          });

          expect(state.children[state.parentItem.reference]).toEqual(
            expect.arrayContaining(['foo']),
          );
          expect(state.children[newParentItem.parentReference]).toEqual(
            expect.arrayContaining(['bar']),
          );
        });

        it('should update itemHasChildren flags', () => {
          const newParentItem = {
            parentReference: '&2',
          };
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['bar'];
          state.childrenFlags[state.parentItem.reference] = { itemHasChildren: true };

          mutations[types.MOVE_ITEM](state, {
            ...defaultPayload,
            newParentItem,
            oldIndex: 0,
            isFirstChild: true,
          });

          expect(state.children[state.parentItem.reference].length).toEqual(0);
          expect(state.childrenFlags[state.parentItem.reference].itemHasChildren).toEqual(false);
          expect(state.children[newParentItem.parentReference]).toEqual(
            expect.arrayContaining(['bar']),
          );
          expect(state.childrenFlags[newParentItem.parentReference].itemHasChildren).toEqual(true);
        });
      });

      describe(types.MOVE_ITEM_FAILURE, () => {
        it('should move an item from one parent to another with children based on provided indexes', () => {
          const newParentItem = {
            parentReference: '&2',
          };
          state.parentItem = { reference: '&1' };
          state.children[state.parentItem.reference] = ['foo'];
          state.children[newParentItem.parentReference] = ['bar', 'baz'];

          mutations[types.MOVE_ITEM_FAILURE](state, {
            oldParentItem: {
              reference: '&1',
            },
            newParentItem,
            targetItem: 'bar',
            oldIndex: 1,
            newIndex: 0,
            isFirstChild: false,
          });

          expect(state.children[state.parentItem.reference]).toEqual(
            expect.arrayContaining(['foo', 'bar']),
          );
          expect(state.children[newParentItem.parentReference]).toEqual(
            expect.arrayContaining(['baz']),
          );
        });
      });

      describe(types.REQUEST_PROJECTS, () => {
        it('should set `projectsFetchInProgress` to true within state', () => {
          mutations[types.REQUEST_PROJECTS](state);

          expect(state.projectsFetchInProgress).toBe(true);
        });
      });

      describe(types.RECEIVE_PROJECTS_SUCCESS, () => {
        it('should set `projectsFetchInProgress` to false and provided `projects` param as it is within the state', () => {
          const projects = [
            { id: 1, name: 'foo' },
            { id: 2, name: 'bar' },
          ];

          mutations[types.RECEIVE_PROJECTS_SUCCESS](state, projects);

          expect(state.projects).toBe(projects);
          expect(state.projectsFetchInProgress).toBe(false);
        });
      });

      describe(types.RECEIVE_PROJECTS_FAILURE, () => {
        it('should set `projectsFetchInProgress` to false within state', () => {
          mutations[types.RECEIVE_PROJECTS_FAILURE](state);

          expect(state.projectsFetchInProgress).toBe(false);
        });
      });

      describe(types.SET_WEIGHT_SUM, () => {
        it('should set `weightSum` within state', () => {
          const payload = { openedIssues: 10, closedIssues: 5 };
          mutations[types.SET_WEIGHT_SUM](state, payload);

          expect(state.weightSum).toBe(payload);
        });
      });

      describe(types.SET_DEFAULT_PROJECT, () => {
        it('should set `defaultProjectForIssueCreation` within state', () => {
          const payload = { id: 'gid://gitlab/Project/1', nameWithNamespace: 'gitlab-org' };
          mutations[types.SET_DEFAULT_PROJECT_FOR_ISSUE_CREATION](state, payload);

          expect(state.defaultProjectForIssueCreation).toBe(payload);
        });
      });
    });
  });
});
