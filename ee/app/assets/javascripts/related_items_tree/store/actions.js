import Api from 'ee/api';
import { createAlert } from '~/alert';
import { STATUS_OPEN } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_CONFLICT, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import {
  itemAddFailureTypesMap,
  pathIndeterminateErrorMap,
  relatedIssuesRemoveErrorMap,
} from '~/related_issues/constants';
import epicChildren from '../queries/epic_children.query.graphql';

import {
  ChildType,
  idProp,
  relativePositions,
  trackingAddedIssue,
  SNOWPLOW_EPIC_ACTIVITY,
  EPIC_CREATE_ERROR_MESSAGE,
} from '../constants';

import epicChildReorder from '../queries/epic_child_reorder.mutation.graphql';
import { processQueryResponse, formatChildItem, gqClient } from '../utils/epic_utils';

import * as types from './mutation_types';

const trackEpicActivity = (params) => {
  Api.trackRedisHllUserEvent(trackingAddedIssue);

  const { CATEGORY, ACTION, LABEL } = SNOWPLOW_EPIC_ACTIVITY;
  Tracking.event(CATEGORY, ACTION, { label: LABEL, property: trackingAddedIssue, ...params });
};
export const setInitialConfig = ({ commit }, data) => commit(types.SET_INITIAL_CONFIG, data);

export const setInitialParentItem = ({ commit }, data) =>
  commit(types.SET_INITIAL_PARENT_ITEM, data);

export const setChildrenCount = ({ commit, state }, data) =>
  commit(types.SET_CHILDREN_COUNT, { ...state.descendantCounts, ...data });

export const setHealthStatus = ({ commit, state }, data) =>
  commit(types.SET_HEALTH_STATUS, { ...state.healthStatus, ...data });

export const updateChildrenCount = ({ state, dispatch }, { item, isRemoved = false }) => {
  const descendantCounts = {};

  if (item.type === ChildType.Epic) {
    descendantCounts[`${item.state}Epics`] = isRemoved
      ? state.descendantCounts[`${item.state}Epics`] - 1
      : state.descendantCounts[`${item.state}Epics`] + 1;
  } else {
    descendantCounts[`${item.state}Issues`] = isRemoved
      ? state.descendantCounts[`${item.state}Issues`] - 1
      : state.descendantCounts[`${item.state}Issues`] + 1;
  }

  dispatch('setChildrenCount', descendantCounts);
};

export const expandItem = ({ commit }, data) => commit(types.EXPAND_ITEM, data);
export const collapseItem = ({ commit }, data) => commit(types.COLLAPSE_ITEM, data);

export const setItemChildren = (
  { commit, dispatch },
  { parentItem, children, isSubItem, append = false },
) => {
  commit(types.SET_ITEM_CHILDREN, {
    parentItem,
    children,
    isSubItem,
    append,
  });

  if (isSubItem) {
    dispatch('expandItem', {
      parentItem,
    });
  }
};
export const setItemChildrenFlags = ({ commit }, data) =>
  commit(types.SET_ITEM_CHILDREN_FLAGS, data);

export const setEpicPageInfo = ({ commit }, data) => commit(types.SET_EPIC_PAGE_INFO, data);
export const setIssuePageInfo = ({ commit }, data) => commit(types.SET_ISSUE_PAGE_INFO, data);
export const setWeightSum = ({ commit }, data) => commit(types.SET_WEIGHT_SUM, data);

export const requestItems = ({ commit }, data) => commit(types.REQUEST_ITEMS, data);
export const receiveItemsSuccess = ({ commit }, data) => commit(types.RECEIVE_ITEMS_SUCCESS, data);
export const receiveItemsFailure = ({ commit }, data) => {
  createAlert({
    message: s__('Epics|Something went wrong while fetching child epics.'),
  });
  commit(types.RECEIVE_ITEMS_FAILURE, data);
};
export const fetchItems = ({ dispatch }, { parentItem, isSubItem = false }) => {
  const { iid, fullPath } = parentItem;

  dispatch('requestItems', {
    parentItem,
    isSubItem,
  });

  gqClient
    .query({
      query: epicChildren,
      variables: { iid, fullPath },
    })
    .then(({ data }) => {
      const children = processQueryResponse(data.group);

      dispatch('receiveItemsSuccess', {
        parentItem,
        children,
        isSubItem,
      });

      dispatch('setItemChildren', {
        parentItem,
        children,
        isSubItem,
      });

      dispatch('setItemChildrenFlags', {
        children,
        isSubItem,
      });

      dispatch('setDefaultProjectForIssueCreation', data.group.epic.defaultProjectForIssueCreation);

      dispatch('setEpicPageInfo', {
        parentItem,
        pageInfo: data.group.epic.children.pageInfo,
      });

      dispatch('setIssuePageInfo', {
        parentItem,
        pageInfo: data.group.epic.issues.pageInfo,
      });

      if (!isSubItem) {
        dispatch('setWeightSum', data.group.epic.descendantWeightSum);
        dispatch('setChildrenCount', data.group.epic.descendantCounts);
        dispatch('setHealthStatus', data.group.epic.healthStatus);
      }
    })
    .catch(() => {
      dispatch('receiveItemsFailure', {
        parentItem,
        isSubItem,
      });
    });
};

export const receiveNextPageItemsFailure = () => {
  createAlert({
    message: s__('Epics|Something went wrong while fetching child epics.'),
  });
};
export const fetchNextPageItems = ({ dispatch, state }, { parentItem, isSubItem = false }) => {
  const { iid, fullPath } = parentItem;
  const parentItemFlags = state.childrenFlags[parentItem.reference];
  const variables = { iid, fullPath };

  if (parentItemFlags.hasMoreEpics) {
    variables.epicEndCursor = parentItemFlags.epicEndCursor;
  }

  if (parentItemFlags.hasMoreIssues) {
    variables.issueEndCursor = parentItemFlags.issueEndCursor;
  }

  return gqClient
    .query({
      query: epicChildren,
      variables,
    })
    .then(({ data }) => {
      const { epic } = data.group;
      const emptyChildren = { edges: [], pageInfo: epic.children.pageInfo };
      const emptyIssues = { edges: [], pageInfo: epic.issues.pageInfo };

      // Ensure we don't re-render already existing items
      const children = processQueryResponse({
        epic: {
          children: parentItemFlags.hasMoreEpics ? epic.children : emptyChildren,
          issues: parentItemFlags.hasMoreIssues ? epic.issues : emptyIssues,
        },
      });

      dispatch('setItemChildren', {
        parentItem,
        children,
        isSubItem,
        append: true,
      });

      dispatch('setItemChildrenFlags', {
        children,
        isSubItem: false,
      });

      dispatch('setEpicPageInfo', {
        parentItem,
        pageInfo: data.group.epic.children.pageInfo,
      });

      dispatch('setIssuePageInfo', {
        parentItem,
        pageInfo: data.group.epic.issues.pageInfo,
      });
    })
    .catch(() => {
      dispatch('receiveNextPageItemsFailure', {
        parentItem,
      });
    });
};

export const toggleItem = ({ state, dispatch }, { parentItem, isDragging = false }) => {
  if (!state.childrenFlags[parentItem.reference].itemExpanded) {
    if (!state.children[parentItem.reference]) {
      dispatch('fetchItems', {
        parentItem,
        isSubItem: true,
      });
    } else {
      dispatch('expandItem', {
        parentItem,
      });
    }
  } else if (!isDragging) {
    dispatch('collapseItem', {
      parentItem,
    });
  }
};

export const setRemoveItemModalProps = ({ commit }, data) =>
  commit(types.SET_REMOVE_ITEM_MODAL_PROPS, data);
export const requestRemoveItem = ({ commit }, data) => commit(types.REQUEST_REMOVE_ITEM, data);
export const receiveRemoveItemSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_REMOVE_ITEM_SUCCESS, data);
export const receiveRemoveItemFailure = ({ commit }, { item, status }) => {
  commit(types.RECEIVE_REMOVE_ITEM_FAILURE, { item });
  const issuableType = item.type.toLowerCase();
  createAlert({
    message:
      status === HTTP_STATUS_NOT_FOUND
        ? pathIndeterminateErrorMap[issuableType]
        : relatedIssuesRemoveErrorMap[issuableType],
  });
};
export const removeItem = ({ state, dispatch }, { parentItem, item }) => {
  dispatch('requestRemoveItem', {
    item,
  });

  axios
    .delete(item.relationPath)
    .then(() => {
      dispatch('receiveRemoveItemSuccess', {
        parentItem,
        item,
      });

      dispatch('fetchItems', {
        parentItem: state.parentItem,
      });
    })
    .catch(({ status }) => {
      dispatch('receiveRemoveItemFailure', {
        item,
        status,
      });
    });
};

export const toggleAddItemForm = ({ commit }, data) => commit(types.TOGGLE_ADD_ITEM_FORM, data);
export const toggleCreateEpicForm = ({ commit }, data) =>
  commit(types.TOGGLE_CREATE_EPIC_FORM, data);
export const toggleCreateIssueForm = ({ commit }, data) =>
  commit(types.TOGGLE_CREATE_ISSUE_FORM, data);

export const setPendingReferences = ({ commit }, data) =>
  commit(types.SET_PENDING_REFERENCES, data);
export const addPendingReferences = ({ commit }, data) =>
  commit(types.ADD_PENDING_REFERENCES, data);
export const removePendingReference = ({ commit }, data) =>
  commit(types.REMOVE_PENDING_REFERENCE, data);
export const setItemInputValue = ({ commit }, data) => commit(types.SET_ITEM_INPUT_VALUE, data);

export const requestAddItem = ({ commit }) => commit(types.REQUEST_ADD_ITEM);
export const receiveAddItemSuccess = ({ dispatch, commit, getters }, { rawItems }) => {
  const items = rawItems.map((item) => {
    // This is needed since Rails API to add Epic/Issue
    // doesn't return global ID string.
    // We can remove this change once add epic/issue
    // action is moved to GraphQL.
    // See https://gitlab.com/gitlab-org/gitlab/issues/34529
    const globalItemId = {};
    if (getters.isEpic) {
      globalItemId.id = !`${item.id}`.includes('gid://') ? `gid://gitlab/Epic/${item.id}` : item.id;
    } else {
      globalItemId.epicIssueId = !`${item.epic_issue_id}`.includes('gid://')
        ? `gid://gitlab/EpicIssue/${item.epic_issue_id}`
        : item.epic_issue_id;
    }

    return formatChildItem({
      ...convertObjectPropsToCamelCase(item, {
        deep: !getters.isEpic,
        dropKeys: ['id', 'epic_issue_id'],
      }),
      ...globalItemId,
      type: getters.isEpic ? ChildType.Epic : ChildType.Issue,
      userPermissions: getters.isEpic ? { canAdmin: item.can_admin } : {},
    });
  });

  commit(types.RECEIVE_ADD_ITEM_SUCCESS, {
    insertAt: 0,
    items,
  });

  dispatch('setItemChildrenFlags', {
    children: items,
    isSubItem: false,
  });

  dispatch('setPendingReferences', []);
  dispatch('setItemInputValue', '');
  dispatch('toggleAddItemForm', { toggleState: false });
};
export const receiveAddItemFailure = (
  { commit },
  { itemAddFailureType, itemAddFailureMessage = '' } = {},
) => {
  commit(types.RECEIVE_ADD_ITEM_FAILURE, { itemAddFailureType, itemAddFailureMessage });
};
export const addItem = ({ state, dispatch, getters }) => {
  dispatch('requestAddItem');

  axios
    .post(getters.isEpic ? state.epicsEndpoint : state.issuesEndpoint, {
      issuable_references: state.pendingReferences,
    })
    .then(({ data }) => {
      trackEpicActivity({ namespace: state.parentItem?.groupId });

      dispatch('receiveAddItemSuccess', {
        // Newly added item is always first in the list
        rawItems: data.issuables.slice(0, state.pendingReferences.length),
      });
      dispatch('fetchItems', {
        parentItem: state.parentItem,
      });
    })
    .catch((data) => {
      const { response } = data;
      if (response.status === HTTP_STATUS_NOT_FOUND) {
        dispatch('receiveAddItemFailure', { itemAddFailureType: itemAddFailureTypesMap.NOT_FOUND });
      }
      // Ignore 409 conflict when the issue or epic is already attached to epic
      else if (
        response.status === HTTP_STATUS_CONFLICT &&
        response.data.message === 'Epic hierarchy level too deep' // eslint-disable-line @gitlab/require-i18n-strings
      ) {
        dispatch('receiveAddItemFailure', {
          itemAddFailureType: itemAddFailureTypesMap.MAX_NUMBER_OF_CHILD_EPICS,
        });
      } else {
        dispatch('receiveAddItemFailure', {
          itemAddFailureMessage: response.data.message,
        });
      }
    });
};

export const requestCreateItem = ({ commit }) => commit(types.REQUEST_CREATE_ITEM);
export const receiveCreateItemSuccess = ({ state, commit, dispatch, getters }, { rawItem }) => {
  const item = formatChildItem({
    ...convertObjectPropsToCamelCase(rawItem, { deep: !getters.isEpic }),
    type: getters.isEpic ? ChildType.Epic : ChildType.Issue,
    // This is needed since Rails API to create Epic
    // doesn't return global ID, we can remove this
    // change once create epic action is moved to
    // GraphQL.
    id: `gid://gitlab/Epic/${rawItem.id}`,
    reference: `${state.parentItem.fullPath}${rawItem.reference}`,
  });

  commit(types.RECEIVE_CREATE_ITEM_SUCCESS, {
    insertAt: 0,
    item,
  });

  dispatch('updateChildrenCount', { item });

  dispatch('setItemChildrenFlags', {
    children: [item],
    isSubItem: false,
  });

  dispatch('toggleCreateEpicForm', { toggleState: false });
};
export const receiveCreateItemFailure = ({ commit }, { message }) => {
  commit(types.RECEIVE_CREATE_ITEM_FAILURE);
  createAlert({ message: message || EPIC_CREATE_ERROR_MESSAGE });
};
export const createItem = ({ state, dispatch }, { itemTitle, groupFullPath }) => {
  dispatch('requestCreateItem');

  Api.createChildEpic({
    confidential: state.parentItem.confidential,
    groupId: groupFullPath || state.parentItem.fullPath,
    parentEpicId: Number(state.parentItem.id.match(/\d.*/)),
    title: itemTitle,
  })
    .then(({ data }) => {
      Object.assign(data, {
        // TODO: API response is missing these 3 keys.
        // Once support is added, we need to remove it from here.
        path: data.url ? `/groups/${data.url.split('/groups/').pop()}` : '',
        state: STATUS_OPEN,
        created_at: '',
      });

      dispatch('receiveCreateItemSuccess', { rawItem: data });
      dispatch('fetchItems', {
        parentItem: state.parentItem,
      });
    })
    .catch(({ response }) => {
      const message = response.data.message?.parent;
      dispatch('receiveCreateItemFailure', { message });
    });
};

export const receiveReorderItemFailure = ({ commit }, data) => {
  commit(types.REORDER_ITEM, data);
  createAlert({
    message: s__('Epics|Something went wrong while ordering item.'),
  });
};
export const reorderItem = (
  { dispatch, commit },
  { treeReorderMutation, parentItem, targetItem, oldIndex, newIndex },
) => {
  // We proactively update the store to reflect new order of item
  commit(types.REORDER_ITEM, { parentItem, targetItem, oldIndex, newIndex });

  return gqClient
    .mutate({
      mutation: epicChildReorder,
      variables: {
        epicTreeReorderInput: {
          baseEpicId: parentItem.id,
          moved: treeReorderMutation,
        },
      },
    })
    .then(({ data }) => {
      // Mutation was unsuccessful;
      // revert to original order and show alert error
      if (data.epicTreeReorder.errors.length) {
        dispatch('receiveReorderItemFailure', {
          parentItem,
          targetItem,
          oldIndex: newIndex,
          newIndex: oldIndex,
        });
      }
    })
    .catch(() => {
      // Mutation was unsuccessful;
      // revert to original order and show alert error
      dispatch('receiveReorderItemFailure', {
        parentItem,
        targetItem,
        oldIndex: newIndex,
        newIndex: oldIndex,
      });
    });
};

export const receiveMoveItemFailure = ({ commit }, data) => {
  commit(types.MOVE_ITEM_FAILURE, data);
  createAlert({
    message: s__('Epics|Something went wrong while moving item.'),
  });
};

export const moveItem = (
  { dispatch, commit, state },
  { oldParentItem, newParentItem, targetItem, oldIndex, newIndex },
) => {
  let adjacentItem;
  let adjacentReferenceId;
  let relativePosition = relativePositions.After;

  let isFirstChild = false;
  const newParentChildren = state.children[newParentItem.parentReference];

  if (newParentChildren?.length > 0) {
    adjacentItem = newParentChildren[newIndex];
    if (!adjacentItem) {
      adjacentItem = newParentChildren[newParentChildren.length - 1];
      relativePosition = relativePositions.Before;
    }
    adjacentReferenceId = adjacentItem[idProp[adjacentItem.type]];
  } else {
    isFirstChild = true;
    relativePosition = relativePositions.Before;
  }

  commit(types.MOVE_ITEM, {
    oldParentItem,
    newParentItem,
    targetItem,
    oldIndex,
    newIndex,
    isFirstChild,
  });

  return gqClient
    .mutate({
      mutation: epicChildReorder,
      variables: {
        epicTreeReorderInput: {
          baseEpicId: oldParentItem.id,
          moved: {
            id: targetItem[idProp[targetItem.type]],
            adjacentReferenceId,
            relativePosition,
            newParentId: newParentItem.parentId,
          },
        },
      },
    })
    .then(({ data }) => {
      // Mutation was unsuccessful;
      // revert to original order and show alert error
      if (data.epicTreeReorder.errors.length) {
        dispatch('receiveMoveItemFailure', {
          oldParentItem,
          newParentItem,
          targetItem,
          newIndex,
          oldIndex,
        });
      }
    })
    .catch(() => {
      // Mutation was unsuccessful;
      // revert to original order and show alert error
      dispatch('receiveMoveItemFailure', {
        oldParentItem,
        newParentItem,
        targetItem,
        newIndex,
        oldIndex,
      });
    });
};

export const receiveCreateIssueSuccess = ({ commit }) =>
  commit(types.RECEIVE_CREATE_ITEM_SUCCESS, { insertAt: 0, items: [] });
export const receiveCreateIssueFailure = ({ commit }) => {
  commit(types.RECEIVE_CREATE_ITEM_FAILURE);
  createAlert({
    message: s__('Epics|Something went wrong while creating issue.'),
  });
};
export const createNewIssue = ({ state, dispatch }, { issuesEndpoint, title }) => {
  const { parentItem } = state;

  // necessary because parentItem comes from GraphQL and we are using REST API here
  const epicId = parseInt(parentItem.id.replace(/^gid:\/\/gitlab\/Epic\//, ''), 10);

  dispatch('requestCreateItem');
  return axios
    .post(issuesEndpoint, { epic_id: epicId, title })
    .then(({ data }) => {
      const { author, epic } = data;
      trackEpicActivity({ user: author?.id, namespace: epic?.group_id });

      dispatch('receiveCreateIssueSuccess', data);
      dispatch('fetchItems', {
        parentItem,
      });
    })
    .catch((e) => {
      dispatch('receiveCreateIssueFailure');
      throw e;
    });
};

export const requestProjects = ({ commit }) => commit(types.REQUEST_PROJECTS);
export const receiveProjectsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_PROJECTS_SUCCESS, data);
export const receiveProjectsFailure = ({ commit }) => {
  commit(types.RECEIVE_PROJECTS_FAILURE);
  createAlert({
    message: __('Something went wrong while fetching projects.'),
  });
};
export const fetchProjects = ({ state, dispatch }, searchKey = '') => {
  const params = {
    include_subgroups: true,
    order_by: 'last_activity_at',
    with_issues_enabled: true,
    with_shared: false,
    search_namespaces: true,
  };

  if (searchKey) {
    params.search = searchKey;
  }

  dispatch('requestProjects');
  axios
    .get(state.projectsEndpoint, {
      params,
    })
    .then(({ data }) => {
      dispatch('receiveProjectsSuccess', data);
    })
    .catch(() => dispatch('receiveProjectsFailure'));
};

export const fetchDescendantGroups = ({ commit }, { groupId, search = '' }) => {
  commit(types.REQUEST_DESCENDANT_GROUPS);

  return Api.descendantGroups({ groupId, search })
    .then(({ data }) => {
      commit(types.RECEIVE_DESCENDANT_GROUPS_SUCCESS, data);
    })
    .catch(() => {
      commit(types.RECEIVE_DESCENDANT_GROUPS_FAILURE);
    });
};

export const setShowLabels = ({ commit }, val) => {
  commit(types.SET_SHOW_LABELS, val);
};

export const setDefaultProjectForIssueCreation = ({ commit }, val) => {
  commit(types.SET_DEFAULT_PROJECT_FOR_ISSUE_CREATION, val);
};
