import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { fullEpicBoardId } from 'ee_component/boards/boards_util';

import BoardApp from '~/boards/components/board_app.vue';
import store from '~/boards/stores';

import '~/boards/filters/due_date_filters';
import {
  NavigationType,
  isLoggedIn,
  parseBoolean,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import { defaultClient } from '~/graphql_shared/issuable_client';
import { TYPE_EPIC, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { queryToObject } from '~/lib/utils/url_utility';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient,
});

function mountBoardApp(el) {
  const { boardId, groupId, fullPath, rootPath } = el.dataset;
  const isApolloBoard = window.gon?.features?.apolloBoards;

  const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });

  const initialFilterParams = {
    ...convertObjectPropsToCamelCase(rawFilterParams),
  };

  const boardType = el.dataset.parent;

  if (!isApolloBoard) {
    store.dispatch('fetchEpicBoard', {
      fullPath,
      boardId: fullEpicBoardId(boardId),
    });

    store.dispatch('setInitialBoardData', {
      allowSubEpics: parseBoolean(el.dataset.subEpicsFeatureAvailable),
      boardType,
      disabled: parseBoolean(el.dataset.disabled) || true,
      issuableType: TYPE_EPIC,
      boardId,
      fullBoardId: fullEpicBoardId(boardId),
      fullPath,
    });
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'BoardRoot',
    store,
    apolloProvider,
    provide: {
      isApolloBoard,
      initialBoardId: fullEpicBoardId(boardId),
      disabled: parseBoolean(el.dataset.disabled),
      boardId,
      groupId: parseInt(groupId, 10),
      rootPath,
      fullPath,
      initialFilterParams,
      boardBaseUrl: el.dataset.boardBaseUrl,
      boardType,
      isGroupBoard: boardType === WORKSPACE_GROUP,
      isProjectBoard: boardType === WORKSPACE_PROJECT,
      currentUserId: gon.current_user_id || null,
      labelsFetchPath: el.dataset.labelsFetchPath,
      labelsManagePath: el.dataset.labelsManagePath,
      labelsFilterBasePath: el.dataset.labelsFilterBasePath,
      timeTrackingLimitToHours: parseBoolean(el.dataset.timeTrackingLimitToHours),
      boardWeight: el.dataset.boardWeight ? parseInt(el.dataset.boardWeight, 10) : null,
      issuableType: TYPE_EPIC,
      emailsDisabled: parseBoolean(el.dataset.emailsDisabled),
      hasMissingBoards: parseBoolean(el.dataset.hasMissingBoards),
      weights: JSON.parse(el.dataset.weights),
      isIssueBoard: false,
      isEpicBoard: true,
      // Permissions
      canUpdate: parseBoolean(el.dataset.canUpdate),
      canAdminList: parseBoolean(el.dataset.canAdminList),
      canAdminBoard: parseBoolean(el.dataset.canAdminBoard),
      canCreateEpic: parseBoolean(el.dataset.canCreateEpic),
      allowLabelCreate: parseBoolean(el.dataset.canUpdate),
      allowLabelEdit: parseBoolean(el.dataset.canUpdate),
      allowScopedLabels: parseBoolean(el.dataset.scopedLabels),
      isSignedIn: isLoggedIn(),
      // Features
      multipleAssigneesFeatureAvailable: parseBoolean(el.dataset.multipleAssigneesFeatureAvailable),
      epicFeatureAvailable: parseBoolean(el.dataset.epicFeatureAvailable),
      iterationFeatureAvailable: parseBoolean(el.dataset.iterationFeatureAvailable),
      weightFeatureAvailable: parseBoolean(el.dataset.weightFeatureAvailable),
      healthStatusFeatureAvailable: parseBoolean(el.dataset.healthStatusFeatureAvailable),
      scopedLabelsAvailable: parseBoolean(el.dataset.scopedLabels),
      milestoneListsAvailable: false,
      assigneeListsAvailable: false,
      iterationListsAvailable: false,
      swimlanesFeatureAvailable: false,
      multipleIssueBoardsAvailable: true,
      scopedIssueBoardFeatureEnabled: true,
    },
    render: (createComponent) => createComponent(BoardApp),
  });
}

export default () => {
  const $boardApp = document.getElementById('js-issuable-board-app');

  // check for browser back and trigger a hard reload to circumvent browser caching.
  window.addEventListener('pageshow', (event) => {
    const isNavTypeBackForward =
      window.performance && window.performance.navigation.type === NavigationType.TYPE_BACK_FORWARD;

    if (event.persisted || isNavTypeBackForward) {
      window.location.reload();
    }
  });

  mountBoardApp($boardApp);
};
