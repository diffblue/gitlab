// This is a true violation of @gitlab/no-runtime-template-compiler, as it
// relies on app/views/shared/boards/_show.html.haml for its
// template.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { IntrospectionFragmentMatcher } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions, mapState } from 'vuex';

import initFilteredSearch from 'ee/boards/epic_filtered_search';
import { fullEpicBoardId, transformBoardConfig } from 'ee_component/boards/boards_util';
import toggleLabels from 'ee_component/boards/toggle_labels';

import BoardAddNewColumnTrigger from '~/boards/components/board_add_new_column_trigger.vue';
import BoardContent from '~/boards/components/board_content.vue';
import boardConfigToggle from '~/boards/config_toggle';
import { issuableTypes } from '~/boards/constants';
import mountMultipleBoardsSwitcher from '~/boards/mount_multiple_boards_switcher';
import store from '~/boards/stores';
import createDefaultClient from '~/lib/graphql';

import '~/boards/filters/due_date_filters';
import { NavigationType, parseBoolean } from '~/lib/utils/common_utils';
import { updateHistory } from '~/lib/utils/url_utility';
import introspectionQueryResultData from '~/sidebar/fragmentTypes.json';

Vue.use(VueApollo);

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData,
});

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      cacheConfig: {
        fragmentMatcher,
      },
      assumeImmutableResults: true,
    },
  ),
});

export default () => {
  const $boardApp = document.getElementById('board-app');

  // check for browser back and trigger a hard reload to circumvent browser caching.
  window.addEventListener('pageshow', (event) => {
    const isNavTypeBackForward =
      window.performance && window.performance.navigation.type === NavigationType.TYPE_BACK_FORWARD;

    if (event.persisted || isNavTypeBackForward) {
      window.location.reload();
    }
  });

  initFilteredSearch(apolloProvider);

  // eslint-disable-next-line no-new
  new Vue({
    el: $boardApp,
    components: {
      BoardContent,
      BoardSettingsSidebar: () => import('~/boards/components/board_settings_sidebar.vue'),
    },
    provide: {
      boardId: $boardApp.dataset.boardId,
      groupId: parseInt($boardApp.dataset.groupId, 10),
      rootPath: $boardApp.dataset.rootPath,
      currentUserId: gon.current_user_id || null,
      canUpdate: parseBoolean($boardApp.dataset.canUpdate),
      canAdminList: parseBoolean($boardApp.dataset.canAdminList),
      labelsFetchPath: $boardApp.dataset.labelsFetchPath,
      labelsManagePath: $boardApp.dataset.labelsManagePath,
      labelsFilterBasePath: $boardApp.dataset.labelsFilterBasePath,
      timeTrackingLimitToHours: parseBoolean($boardApp.dataset.timeTrackingLimitToHours),
      weightFeatureAvailable: parseBoolean($boardApp.dataset.weightFeatureAvailable),
      boardWeight: $boardApp.dataset.boardWeight
        ? parseInt($boardApp.dataset.boardWeight, 10)
        : null,
      scopedLabelsAvailable: parseBoolean($boardApp.dataset.scopedLabels),
      milestoneListsAvailable: false,
      assigneeListsAvailable: false,
      iterationListsAvailable: false,
      emailsDisabled: parseBoolean($boardApp.dataset.emailsDisabled),
    },
    store,
    apolloProvider,
    data() {
      return {
        state: {},
        loading: 0,
        allowSubEpics: parseBoolean($boardApp.dataset.subEpicsFeatureAvailable),
        boardsEndpoint: $boardApp.dataset.boardsEndpoint,
        recentBoardsEndpoint: $boardApp.dataset.recentBoardsEndpoint,
        listsEndpoint: $boardApp.dataset.listsEndpoint,
        disabled: parseBoolean($boardApp.dataset.disabled),
        bulkUpdatePath: $boardApp.dataset.bulkUpdatePath,
        parent: $boardApp.dataset.parent,
        detailIssueVisible: false,
      };
    },
    computed: {
      ...mapState(['boardConfig']),
    },
    created() {
      this.setInitialBoardData({
        allowSubEpics: this.allowSubEpics,
        boardId: $boardApp.dataset.boardId,
        fullBoardId: fullEpicBoardId($boardApp.dataset.boardId),
        fullPath: $boardApp.dataset.fullPath,
        boardType: this.parent,
        disabled: this.disabled,
        issuableType: issuableTypes.epic,
        boardConfig: {
          milestoneId: parseInt($boardApp.dataset.boardMilestoneId, 10),
          milestoneTitle: $boardApp.dataset.boardMilestoneTitle || '',
          iterationId: parseInt($boardApp.dataset.boardIterationId, 10),
          iterationTitle: $boardApp.dataset.boardIterationTitle || '',
          assigneeId: $boardApp.dataset.boardAssigneeId,
          assigneeUsername: $boardApp.dataset.boardAssigneeUsername,
          labels: $boardApp.dataset.labels ? JSON.parse($boardApp.dataset.labels) : [],
          labelIds: $boardApp.dataset.labelIds ? JSON.parse($boardApp.dataset.labelIds) : [],
          weight: $boardApp.dataset.boardWeight
            ? parseInt($boardApp.dataset.boardWeight, 10)
            : null,
        },
      });
    },
    mounted() {
      const boardConfigPath = transformBoardConfig(this.boardConfig);
      if (boardConfigPath !== '') {
        const filterPath = window.location.search ? `${window.location.search}&` : '?';
        updateHistory({
          url: `${filterPath}${transformBoardConfig(this.boardConfig)}`,
        });
      }
      this.performSearch();
    },
    methods: {
      ...mapActions(['setInitialBoardData', 'performSearch']),
      getNodes(data) {
        return data[this.parent]?.board?.lists.nodes;
      },
    },
  });

  const createColumnTriggerEl = document.querySelector('.js-create-column-trigger');
  if (createColumnTriggerEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: createColumnTriggerEl,
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
