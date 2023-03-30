<script>
import { GlButton, GlIcon, GlLink, GlLoadingIcon, GlPopover, GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { STATUS_OPEN } from '~/issues/constants';
import { formatDate } from '~/lib/utils/datetime_utility';
import { __, n__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatListIssuesForLanes } from 'ee/boards/boards_util';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { BoardType } from 'ee_else_ce/boards/constants';
import IssuesLaneList from './issues_lane_list.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    IssuesLaneList,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  inject: ['fullPath', 'boardType', 'isApolloBoard'],
  props: {
    epic: {
      type: Object,
      required: true,
    },
    lists: {
      type: Array,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
    boardId: {
      type: String,
      required: true,
    },
    filterParams: {
      type: Object,
      required: true,
    },
  },
  data() {
    const { userPreferences } = this.epic;

    const { collapsed = false } = userPreferences || {};

    return {
      isCollapsed: collapsed,
      listsWithIssues: [],
    };
  },
  apollo: {
    listsWithIssues: {
      query: listsIssuesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          boardId: this.boardId,
          filters: { ...this.filterParams, epicId: this.epic.id },
          isGroup: this.boardType === BoardType.group,
          isProject: this.boardType === BoardType.project,
        };
      },
      context: {
        isSingleRequest: true,
      },
      skip() {
        return !this.isApolloBoard;
      },
      update(data) {
        return data[this.boardType]?.board.lists.nodes;
      },
    },
  },
  computed: {
    ...mapState(['epicsFlags']),
    ...mapGetters(['getIssuesByEpic']),
    isOpen() {
      return this.epic.state === STATUS_OPEN;
    },
    chevronTooltip() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
    chevronIcon() {
      return this.isCollapsed ? 'chevron-right' : 'chevron-down';
    },
    issuesCount() {
      if (this.isApolloBoard) {
        return this.listsWithIssues.reduce((total, list) => total + list.issues.nodes.length, 0);
      }
      return this.lists.reduce(
        (total, list) => total + this.getIssuesByEpic(list.id, this.epic.id).length,
        0,
      );
    },
    issuesCountTooltipText() {
      return n__(`%d issue in this group`, `%d issues in this group`, this.issuesCount);
    },
    epicTimeAgoString() {
      return this.isOpen
        ? sprintf(__(`Created %{epicTimeagoDate}`), {
            epicTimeagoDate: this.timeFormatted(this.epic.createdAt),
          })
        : sprintf(__(`Closed %{epicTimeagoDate}`), {
            epicTimeagoDate: this.timeFormatted(this.epic.closedAt),
          });
    },
    epicDateString() {
      return formatDate(this.epic.createdAt);
    },
    isLoading() {
      return Boolean(this.epicsFlags[this.epic.id]?.isLoading);
    },
    shouldDisplay() {
      return this.issuesCount > 0 || this.isLoading;
    },
    showUnassignedLane() {
      return !this.isCollapsed && this.issuesCount > 0;
    },
    issuesByList() {
      return formatListIssuesForLanes(this.listsWithIssues);
    },
  },
  watch: {
    'filterParams.epicId': {
      handler(epicId) {
        if (!epicId || epicId === this.epic.id) {
          this.fetchIssuesForEpic(this.epic.id);
        }
      },
      deep: true,
    },
  },
  mounted() {
    this.fetchIssuesForEpic(this.epic.id);
  },
  methods: {
    ...mapActions(['updateBoardEpicUserPreferences', 'setError', 'fetchIssuesForEpic']),
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;

      this.updateBoardEpicUserPreferences({
        collapsed: this.isCollapsed,
        epicId: this.epic.id,
      }).catch(() => {
        this.setError({ message: __('Unable to save your preference'), captureError: true });
      });
    },
    getIssuesByList(listId) {
      if (this.isApolloBoard) {
        return this.issuesByList[listId];
      }
      return this.getIssuesByEpic(listId, this.epic.id);
    },
  },
};
</script>

<template>
  <div v-if="shouldDisplay" class="board-epic-lane-container">
    <div
      class="board-epic-lane gl-w-full gl-max-w-full gl-sticky gl-left-0 gl-display-inline-block"
      :class="{
        'board-epic-lane-shadow': !isCollapsed,
      }"
      data-testid="board-epic-lane"
    >
      <div class="gl-py-3 gl-px-3 gl-display-flex gl-align-items-center">
        <gl-button
          v-gl-tooltip.hover.right
          :aria-label="chevronTooltip"
          :title="chevronTooltip"
          :icon="chevronIcon"
          class="gl-mr-2 gl-cursor-pointer"
          category="tertiary"
          size="small"
          @click="toggleCollapsed"
        />
        <h4
          ref="epicTitle"
          class="gl-my-0 gl-mr-3 gl-font-weight-bold gl-font-base gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
        >
          {{ epic.title }}
        </h4>
        <gl-popover :target="() => $refs.epicTitle" placement="top">
          <template #title>{{ epic.title }} &middot; {{ epic.reference }}</template>
          <div>{{ epicTimeAgoString }}</div>
          <div class="gl-mb-2">{{ epicDateString }}</div>
          <gl-link :href="epic.webUrl" class="gl-font-sm">{{ __('Go to epic') }}</gl-link>
        </gl-popover>
        <span
          v-if="!isLoading"
          v-gl-tooltip.hover
          :title="issuesCountTooltipText"
          class="gl-display-flex gl-align-items-center gl-text-gray-500"
          tabindex="0"
          :aria-label="issuesCountTooltipText"
          data-testid="epic-lane-issue-count"
        >
          <gl-icon class="gl-mr-2 gl-flex-shrink-0" name="issues" />
          <span aria-hidden="true">{{ issuesCount }}</span>
        </span>
        <gl-loading-icon v-else class="gl-p-2" />
      </div>
    </div>
    <div
      v-if="showUnassignedLane"
      class="gl-display-flex gl-pb-5 board-epic-lane-issues"
      data-testid="board-epic-lane-issues"
    >
      <issues-lane-list
        v-for="list in lists"
        :key="`${list.id}-issues`"
        :list="list"
        :issues="getIssuesByList(list.id)"
        :epic-id="epic.id"
        :epic-is-confidential="epic.confidential"
        :can-admin-list="canAdminList"
        :board-id="boardId"
        :filter-params="filterParams"
      />
    </div>
  </div>
</template>
