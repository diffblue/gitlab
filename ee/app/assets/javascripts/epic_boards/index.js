import Vue from 'vue';
import VueApollo from 'vue-apollo';

import initFilteredSearch from 'ee/boards/epic_filtered_search';
import { fullEpicBoardId } from 'ee_component/boards/boards_util';
import toggleLabels from 'ee_component/boards/toggle_labels';

import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardApp from '~/boards/components/board_app.vue';
import boardConfigToggle from '~/boards/config_toggle';
import { issuableTypes } from '~/boards/constants';
import mountMultipleBoardsSwitcher from '~/boards/mount_multiple_boards_switcher';
import store from '~/boards/stores';
import createDefaultClient from '~/lib/graphql';

import '~/boards/filters/due_date_filters';
import { NavigationType, parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

function mountBoardApp(el) {
  const { boardId, groupId, fullPath, rootPath } = el.dataset;

  store.dispatch('setInitialBoardData', {
    allowSubEpics: parseBoolean(el.dataset.subEpicsFeatureAvailable),
    boardType: el.dataset.parent,
    disabled: parseBoolean(el.dataset.disabled) || true,
    issuableType: issuableTypes.epic,
    boardId,
    fullBoardId: fullEpicBoardId(boardId),
    fullPath,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'BoardRoot',
    store,
    apolloProvider,
    provide: {
      disabled: parseBoolean(el.dataset.disabled),
      boardId,
      groupId: parseInt(groupId, 10),
      rootPath,
      currentUserId: gon.current_user_id || null,
      canUpdate: parseBoolean(el.dataset.canUpdate),
      canAdminList: parseBoolean(el.dataset.canAdminList),
      labelsFetchPath: el.dataset.labelsFetchPath,
      labelsManagePath: el.dataset.labelsManagePath,
      labelsFilterBasePath: el.dataset.labelsFilterBasePath,
      timeTrackingLimitToHours: parseBoolean(el.dataset.timeTrackingLimitToHours),
      multipleAssigneesFeatureAvailable: parseBoolean(el.dataset.multipleAssigneesFeatureAvailable),
      epicFeatureAvailable: parseBoolean(el.dataset.epicFeatureAvailable),
      iterationFeatureAvailable: parseBoolean(el.dataset.iterationFeatureAvailable),
      weightFeatureAvailable: parseBoolean(el.dataset.weightFeatureAvailable),
      boardWeight: el.dataset.boardWeight ? parseInt(el.dataset.boardWeight, 10) : null,
      scopedLabelsAvailable: parseBoolean(el.dataset.scopedLabels),
      milestoneListsAvailable: false,
      assigneeListsAvailable: false,
      iterationListsAvailable: false,
      issuableType: issuableTypes.epic,
      emailsDisabled: parseBoolean(el.dataset.emailsDisabled),
      allowLabelCreate: parseBoolean(el.dataset.canUpdate),
      allowLabelEdit: parseBoolean(el.dataset.canUpdate),
      allowScopedLabels: parseBoolean(el.dataset.scopedLabels),
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

  initFilteredSearch(apolloProvider);

  mountBoardApp($boardApp);

  const createColumnTriggerEl = document.querySelector('.js-create-column-trigger');
  if (createColumnTriggerEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: createColumnTriggerEl,
      name: 'BoardAddNewColumnTriggerRoot',
      components: {
        BoardAddNewColumnTrigger,
      },
      store,
      render(createElement) {
        return createElement(BoardAddNewColumnTrigger);
      },
    });
  }

  toggleLabels();
  boardConfigToggle();

  mountMultipleBoardsSwitcher({
    fullPath: $boardApp.dataset.fullPath,
    rootPath: $boardApp.dataset.boardsEndpoint,
  });
};
