import Vue from 'vue';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_CONFIG](
    state,
    {
      epicsEndpoint,
      issuesEndpoint,
      autoCompleteEpics,
      autoCompleteIssues,
      projectsEndpoint,
      userSignedIn,
      allowIssuableHealthStatus,
      allowScopedLabels,
      allowSubEpics,
      epicsWebUrl,
      isShowingLabels,
      issuesWebUrl,
    },
  ) {
    state.epicsEndpoint = epicsEndpoint;
    state.issuesEndpoint = issuesEndpoint;
    state.autoCompleteEpics = autoCompleteEpics;
    state.autoCompleteIssues = autoCompleteIssues;
    state.projectsEndpoint = projectsEndpoint;
    state.userSignedIn = userSignedIn;
    state.allowIssuableHealthStatus = allowIssuableHealthStatus;
    state.allowScopedLabels = allowScopedLabels;
    state.allowSubEpics = allowSubEpics;
    state.epicsWebUrl = epicsWebUrl;
    state.isShowingLabels = isShowingLabels;
    state.issuesWebUrl = issuesWebUrl;
  },

  [types.SET_INITIAL_PARENT_ITEM](state, data) {
    state.parentItem = { ...data };
    state.childrenFlags[state.parentItem.reference] = {};
  },

  [types.SET_CHILDREN_COUNT](state, data) {
    state.descendantCounts = data;
  },

  [types.SET_HEALTH_STATUS](state, data) {
    state.healthStatus = data;
  },

  [types.SET_DEFAULT_PROJECT_FOR_ISSUE_CREATION](state, data) {
    state.defaultProjectForIssueCreation = data;
  },

  [types.SET_ITEM_CHILDREN](state, { parentItem, children, append }) {
    if (append) {
      state.children[parentItem.reference].push(...children);
    } else {
      Vue.set(state.children, parentItem.reference, children);
    }
  },

  [types.SET_ITEM_CHILDREN_FLAGS](state, { children }) {
    children.forEach((item) => {
      Vue.set(state.childrenFlags, item.reference, {
        itemExpanded: false,
        itemChildrenFetchInProgress: false,
        itemRemoveInProgress: false,
        itemHasChildren: item.hasChildren || item.hasIssues,
      });
    });
  },

  [types.SET_EPIC_PAGE_INFO](state, { parentItem, pageInfo }) {
    const parentFlags = state.childrenFlags[parentItem.reference];

    parentFlags.epicEndCursor = pageInfo.endCursor;
    parentFlags.hasMoreEpics = pageInfo.hasNextPage;
  },

  [types.SET_ISSUE_PAGE_INFO](state, { parentItem, pageInfo }) {
    const parentFlags = state.childrenFlags[parentItem.reference];

    parentFlags.issueEndCursor = pageInfo.endCursor;
    parentFlags.hasMoreIssues = pageInfo.hasNextPage;
  },

  [types.SET_WEIGHT_SUM](state, data) {
    state.weightSum = data;
  },

  [types.REQUEST_ITEMS](state, { parentItem, isSubItem }) {
    if (isSubItem) {
      state.childrenFlags[parentItem.reference].itemChildrenFetchInProgress = true;
    } else {
      state.itemsFetchInProgress = true;
    }
  },
  [types.RECEIVE_ITEMS_SUCCESS](state, { parentItem, children, isSubItem }) {
    if (isSubItem) {
      state.childrenFlags[parentItem.reference].itemChildrenFetchInProgress = false;
    } else {
      state.itemsFetchInProgress = false;
      state.itemsFetchResultEmpty = children.length === 0;
    }
  },
  [types.RECEIVE_ITEMS_FAILURE](state, { parentItem, isSubItem }) {
    if (isSubItem) {
      state.childrenFlags[parentItem.reference].itemChildrenFetchInProgress = false;
    } else {
      state.itemsFetchInProgress = false;
    }
  },

  [types.EXPAND_ITEM](state, { parentItem }) {
    state.childrenFlags[parentItem.reference].itemExpanded = true;
  },
  [types.COLLAPSE_ITEM](state, { parentItem }) {
    state.childrenFlags[parentItem.reference].itemExpanded = false;
  },

  [types.SET_REMOVE_ITEM_MODAL_PROPS](state, { parentItem, item }) {
    state.removeItemModalProps = {
      parentItem,
      item,
    };
  },

  [types.REQUEST_REMOVE_ITEM](state, { item }) {
    state.childrenFlags[item.reference].itemRemoveInProgress = true;
  },
  [types.RECEIVE_REMOVE_ITEM_SUCCESS](state, { parentItem, item }) {
    state.childrenFlags[item.reference].itemRemoveInProgress = false;

    // Remove the children from array
    const targetChildren = state.children[parentItem.reference];
    targetChildren.splice(targetChildren.indexOf(item), 1);

    // Update flag for parentItem so that expand/collapse
    // button visibility is refreshed correctly.
    state.childrenFlags[parentItem.reference].itemHasChildren = Boolean(targetChildren.length);

    // In case item removed belonged to main epic
    // we also set results empty.
    if (
      state.children[state.parentItem.reference] &&
      !state.children[state.parentItem.reference].length
    ) {
      state.itemsFetchResultEmpty = true;
    }
  },
  [types.RECEIVE_REMOVE_ITEM_FAILURE](state, { item }) {
    state.childrenFlags[item.reference].itemRemoveInProgress = false;
  },

  [types.TOGGLE_ADD_ITEM_FORM](state, { issuableType, toggleState }) {
    if (issuableType) {
      state.issuableType = issuableType;
    }

    state.showAddItemForm = toggleState;
    state.showCreateEpicForm = false;
    state.showCreateIssueForm = false;
  },

  [types.TOGGLE_CREATE_EPIC_FORM](state, { toggleState }) {
    state.showCreateEpicForm = toggleState;
    state.showAddItemForm = false;
    state.showCreateIssueForm = false;
    state.issuableType = TYPE_EPIC;
  },

  [types.TOGGLE_CREATE_ISSUE_FORM](state, { toggleState }) {
    state.showCreateIssueForm = toggleState;
    state.showAddItemForm = false;
    state.showCreateEpicForm = false;
    state.issuableType = TYPE_ISSUE;
  },

  [types.SET_PENDING_REFERENCES](state, references) {
    state.pendingReferences = references;
  },

  [types.ADD_PENDING_REFERENCES](state, references) {
    const nonDuplicateReferences = references.filter(
      (ref) => !state.pendingReferences.includes(ref),
    );
    state.pendingReferences.push(...nonDuplicateReferences);
  },

  [types.REMOVE_PENDING_REFERENCE](state, indexToRemove) {
    state.pendingReferences = state.pendingReferences.filter(
      (ref, index) => index !== indexToRemove,
    );
    if (state.pendingReferences.length === 0) {
      state.itemAddFailure = false;
    }
  },

  [types.SET_ITEM_INPUT_VALUE](state, itemInputValue) {
    state.itemInputValue = itemInputValue;
  },

  [types.REQUEST_ADD_ITEM](state) {
    state.itemAddInProgress = true;
  },
  [types.RECEIVE_ADD_ITEM_SUCCESS](state, { insertAt, items }) {
    state.children[state.parentItem.reference].splice(insertAt, 0, ...items);
    state.itemAddInProgress = false;
    state.itemsFetchResultEmpty = false;
  },
  [types.RECEIVE_ADD_ITEM_FAILURE](state, { itemAddFailureType, itemAddFailureMessage }) {
    state.itemAddInProgress = false;
    state.itemAddFailure = true;
    state.itemAddFailureMessage = itemAddFailureMessage;
    if (itemAddFailureType) {
      state.itemAddFailureType = itemAddFailureType;
    }
  },

  [types.REQUEST_CREATE_ITEM](state) {
    state.itemCreateInProgress = true;
  },
  [types.RECEIVE_CREATE_ITEM_SUCCESS](state, { insertAt, item }) {
    state.children[state.parentItem.reference].splice(insertAt, 0, item);
    state.itemCreateInProgress = false;
    state.itemsFetchResultEmpty = false;
  },
  [types.RECEIVE_CREATE_ITEM_FAILURE](state) {
    state.itemCreateInProgress = false;
  },

  [types.REORDER_ITEM](state, { parentItem, targetItem, oldIndex, newIndex }) {
    // Remove from old position
    state.children[parentItem.reference].splice(oldIndex, 1);

    // Insert at new position
    state.children[parentItem.reference].splice(newIndex, 0, targetItem);
  },

  [types.MOVE_ITEM](
    state,
    { oldParentItem, newParentItem, targetItem, oldIndex, newIndex, isFirstChild },
  ) {
    // Remove from old position in previous parent
    state.children[oldParentItem.reference].splice(oldIndex, 1);
    if (state.children[oldParentItem.reference].length === 0) {
      state.childrenFlags[oldParentItem.reference].itemHasChildren = false;
    }

    // Insert at new position in new parent
    if (isFirstChild) {
      Vue.set(state.children, newParentItem.parentReference, [targetItem]);
      Vue.set(state.childrenFlags, newParentItem.parentReference, {
        itemExpanded: true,
        itemHasChildren: true,
      });
    } else {
      state.children[newParentItem.parentReference].splice(newIndex, 0, targetItem);
    }
  },
  [types.MOVE_ITEM_FAILURE](
    state,
    { oldParentItem, newParentItem, targetItem, oldIndex, newIndex },
  ) {
    // Remove from new position in new parent
    state.children[newParentItem.parentReference].splice(newIndex, 1);

    // Insert at old position in old parent
    state.children[oldParentItem.reference].splice(oldIndex, 0, targetItem);
  },

  [types.REQUEST_PROJECTS](state) {
    state.projectsFetchInProgress = true;
  },
  [types.RECEIVE_PROJECTS_SUCCESS](state, projects) {
    state.projects = projects;
    state.projectsFetchInProgress = false;
  },
  [types.RECEIVE_PROJECTS_FAILURE](state) {
    state.projectsFetchInProgress = false;
  },

  [types.REQUEST_DESCENDANT_GROUPS](state) {
    state.descendantGroupsFetchInProgress = true;
  },
  [types.RECEIVE_DESCENDANT_GROUPS_SUCCESS](state, descendantGroups) {
    state.descendantGroups = descendantGroups;
    state.descendantGroupsFetchInProgress = false;
  },
  [types.RECEIVE_DESCENDANT_GROUPS_FAILURE](state) {
    state.descendantGroupsFetchInProgress = false;
  },
  [types.SET_SHOW_LABELS](state, val) {
    state.isShowingLabels = val;
  },
};
