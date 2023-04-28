<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import VirtualList from 'vue-virtual-scroll-list';
import Draggable from 'vuedraggable';
import { mapActions, mapGetters, mapState } from 'vuex';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import { isListDraggable } from '~/boards/boards_util';
import eventHub from '~/boards/eventhub';
import { s__, __ } from '~/locale';
import { defaultSortableOptions } from '~/sortable/constants';
import {
  BoardType,
  DRAGGABLE_TAG,
  EPIC_LANE_BASE_HEIGHT,
  DraggableItemTypes,
} from 'ee/boards/constants';
import { calculateSwimlanesBufferSize } from '../boards_util';
import epicsSwimlanesQuery from '../graphql/epics_swimlanes.query.graphql';
import EpicLane from './epic_lane.vue';
import IssuesLaneList from './issues_lane_list.vue';
import SwimlanesLoadingSkeleton from './swimlanes_loading_skeleton.vue';

export default {
  EpicLane,
  epicLaneBaseHeight: EPIC_LANE_BASE_HEIGHT,
  draggableItemTypes: DraggableItemTypes,
  components: {
    BoardAddNewColumn,
    BoardListHeader,
    EpicLane,
    IssuesLaneList,
    GlButton,
    GlIcon,
    SwimlanesLoadingSkeleton,
    VirtualList,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['boardType', 'disabled', 'fullPath', 'isApolloBoard'],
  props: {
    lists: {
      type: Array,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
    filters: {
      type: Object,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      bufferSize: 0,
      isUnassignedCollapsed: true,
      rawEpics: {},
      isLoadingMore: false,
      hasMoreUnassignedIssuables: {},
      isLoadingMoreIssues: false,
    };
  },
  apollo: {
    rawEpics: {
      query: epicsSwimlanesQuery,
      variables() {
        return {
          ...this.baseVariables,
          issueFilters: this.filterParams,
        };
      },
      skip() {
        return !this.isApolloBoard;
      },
      update(data) {
        return data[this.boardType].board.epics;
      },
    },
  },
  computed: {
    ...mapState([
      'epics',
      'pageInfoByListId',
      'listsFlags',
      'addColumnForm',
      'filterParams',
      'epicsSwimlanesFetchInProgress',
      'hasMoreEpics',
    ]),
    ...mapGetters(['getUnassignedIssues']),
    baseVariables() {
      return {
        fullPath: this.fullPath,
        boardId: this.boardId,
        isGroup: this.boardType === BoardType.group,
        isProject: this.boardType === BoardType.project,
      };
    },
    epicsToUse() {
      return this.isApolloBoard ? this.rawEpics?.nodes || [] : this.epics;
    },
    filtersToUse() {
      return this.isApolloBoard ? this.filters : this.filterParams;
    },
    pageInfo() {
      return this.rawEpics.pageInfo;
    },
    hasMoreEpicsToLoad() {
      return this.isApolloBoard ? this.pageInfo?.hasNextPage : this.hasMoreEpics;
    },
    isLoadingMoreEpics() {
      return this.isApolloBoard
        ? this.isLoadingMore
        : this.epicsSwimlanesFetchInProgress.epicLanesFetchMoreInProgress;
    },
    addColumnFormVisible() {
      return this.addColumnForm?.visible;
    },
    treeRootWrapper() {
      return this.canAdminList ? Draggable : DRAGGABLE_TAG;
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableOptions,
        fallbackOnBody: false,
        group: 'board-swimlanes',
        tag: DRAGGABLE_TAG,
        draggable: '.is-draggable',
        'ghost-class': 'swimlane-header-drag-active',
        value: this.lists,
      };

      return this.canAdminList ? options : {};
    },
    hasMoreUnassignedIssues() {
      if (this.isApolloBoard) {
        return this.lists.some((list) => this.hasMoreUnassignedIssuables[list.id]);
      }
      return this.lists.some((list) => this.pageInfoByListId[list.id]?.hasNextPage);
    },
    isLoading() {
      if (this.isApolloBoard) {
        return this.$apollo.queries.rawEpics.loading && !this.isLoadingMoreEpics;
      }
      const {
        epicLanesFetchInProgress,
        listItemsFetchInProgress,
      } = this.epicsSwimlanesFetchInProgress;
      return epicLanesFetchInProgress || listItemsFetchInProgress;
    },
    chevronTooltip() {
      return this.isUnassignedCollapsed ? __('Expand') : __('Collapse');
    },
    chevronIcon() {
      return this.isUnassignedCollapsed ? 'chevron-right' : 'chevron-down';
    },
    epicButtonLabel() {
      return this.epicsSwimlanesFetchInProgress.epicLanesFetchMoreInProgress
        ? s__('Board|Loading epics')
        : s__('Board|Load more epics');
    },
    shouldShowLoadMoreUnassignedIssues() {
      return !this.isUnassignedCollapsed && this.hasMoreUnassignedIssues;
    },
  },
  watch: {
    filterParams: {
      handler() {
        if (!this.isApolloBoard) {
          Promise.all(this.epics.map((epic) => this.fetchIssuesForEpic(epic.id)))
            .then(() => this.doneLoadingSwimlanesItems())
            .catch(() => {});
        }
      },
      deep: true,
      immediate: true,
    },
  },
  mounted() {
    this.bufferSize = calculateSwimlanesBufferSize(this.$el.offsetTop);
  },
  created() {
    eventHub.$on('open-unassigned-lane', this.openUnassignedLane);
  },
  beforeDestroy() {
    eventHub.$off('open-unassigned-lane', this.openUnassignedLane);
  },
  methods: {
    ...mapActions([
      'moveList',
      'fetchEpicsSwimlanes',
      'fetchIssuesForEpic',
      'fetchItemsForList',
      'doneLoadingSwimlanesItems',
    ]),
    async fetchMoreEpics() {
      if (this.isApolloBoard) {
        this.isLoadingMore = true;
        await this.$apollo.queries.rawEpics.fetchMore({
          variables: {
            ...this.baseVariables,
            issueFilters: this.filterParams,
            after: this.pageInfo.endCursor,
          },
        });
        this.isLoadingMore = false;
      } else {
        this.fetchEpicsSwimlanes({ fetchNext: true });
      }
    },
    fetchMoreUnassignedIssues() {
      if (this.isApolloBoard) {
        this.isLoadingMoreIssues = true;
        return;
      }
      this.lists.forEach((list) => {
        if (this.pageInfoByListId[list.id]?.hasNextPage) {
          this.fetchItemsForList({ listId: list.id, fetchNext: true, noEpicIssues: true });
        }
      });
    },
    isListDraggable(list) {
      return isListDraggable(list);
    },
    afterFormEnters() {
      const container = this.$refs.scrollableContainer;
      container.scrollTo({
        left: container.scrollWidth,
        behavior: 'smooth',
      });
    },
    getEpicLaneProps(index) {
      return {
        key: this.epicsToUse[index].id,
        props: {
          epic: this.epicsToUse[index],
          lists: this.lists,
          disabled: this.disabled,
          canAdminList: this.canAdminList,
          boardId: this.boardId,
          filterParams: this.filtersToUse,
        },
      };
    },
    toggleUnassignedLane() {
      this.isUnassignedCollapsed = !this.isUnassignedCollapsed;
    },
    openUnassignedLane() {
      this.isUnassignedCollapsed = false;
    },
    unassignedIssues(listId) {
      return this.getUnassignedIssues(listId);
    },
    updatePageInfo(pageInfo, listId) {
      this.hasMoreUnassignedIssuables = {
        ...this.hasMoreUnassignedIssuables,
        [listId]: pageInfo.hasNextPage,
      };
    },
  },
};
</script>

<template>
  <div
    ref="scrollableContainer"
    class="board-swimlanes gl-white-space-nowrap gl-pb-5 gl-px-3 gl-display-flex gl-flex-grow-1"
    data-testid="board-swimlanes"
    data_qa_selector="board_epics_swimlanes"
  >
    <swimlanes-loading-skeleton v-if="isLoading" />
    <div v-else class="board-swimlanes-content">
      <component
        :is="treeRootWrapper"
        v-bind="treeRootOptions"
        class="board-swimlanes-headers gl-bg-white gl-display-table gl-sticky gl-pt-5 gl-mb-5 gl-top-0 gl-z-index-3"
        data-testid="board-swimlanes-headers"
        @end="moveList"
      >
        <div
          v-for="list in lists"
          :key="list.id"
          :class="{
            'is-collapsed gl-w-10': list.collapsed,
            'is-draggable': isListDraggable(list),
          }"
          class="board gl-display-inline-block gl-px-3 gl-vertical-align-top gl-white-space-normal"
          :data-list-id="list.id"
          data-testid="board-header-container"
          :data-draggable-item-type="$options.draggableItemTypes.list"
        >
          <board-list-header
            :can-admin-list="canAdminList"
            :list="list"
            :filter-params="filtersToUse"
            :is-swimlanes-header="true"
            @setActiveList="$emit('setActiveList', $event)"
          />
        </div>
      </component>
      <div class="board-epics-swimlanes gl-display-table">
        <virtual-list
          v-if="epicsToUse.length"
          :size="$options.epicLaneBaseHeight"
          :remain="bufferSize"
          :bench="bufferSize"
          :scrollelement="$refs.scrollableContainer"
          :item="$options.EpicLane"
          :itemcount="epicsToUse.length"
          :itemprops="getEpicLaneProps"
        />
        <div v-if="hasMoreEpicsToLoad" class="swimlanes-button gl-pb-3 gl-pl-3 gl-sticky gl-left-0">
          <gl-button
            category="tertiary"
            variant="confirm"
            class="gl-w-full"
            :loading="isLoadingMoreEpics"
            :disabled="isLoadingMoreEpics"
            data-testid="load-more-epics"
            data-track-action="click_button"
            data-track-label="toggle_swimlanes"
            data-track-property="click_load_more_epics"
            @click="fetchMoreEpics"
          >
            {{ epicButtonLabel }}
          </gl-button>
        </div>
        <div>
          <div
            class="board-lane-unassigned-issues-title gl-w-full gl-max-w-full gl-sticky gl-display-inline-block gl-left-0"
            :class="{
              'board-epic-lane-shadow': !isUnassignedCollapsed,
            }"
            data-testid="board-lane-unassigned-issues-title"
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
                data-testid="unassigned-lane-toggle"
                @click="toggleUnassignedLane"
              />
              <span
                class="gl-mr-3 gl-font-weight-bold gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
              >
                {{ __('Issues with no epic assigned') }}
              </span>
            </div>
          </div>
          <div v-if="!isUnassignedCollapsed" data-testid="board-lane-unassigned-issues">
            <div class="gl-display-flex">
              <issues-lane-list
                v-for="list in lists"
                :key="`${list.id}-issues`"
                :list="list"
                :issues="unassignedIssues(list.id)"
                :is-unassigned-issues-lane="true"
                :can-admin-list="canAdminList"
                :board-id="boardId"
                :filter-params="filtersToUse"
                :is-loading-more-issues="isLoadingMoreIssues"
                @updatePageInfo="updatePageInfo"
                @issuesLoaded="isLoadingMoreIssues = false"
              />
            </div>
          </div>
        </div>
      </div>
      <div
        v-if="shouldShowLoadMoreUnassignedIssues"
        class="swimlanes-button gl-p-3 gl-pr-0 gl-sticky gl-left-0"
      >
        <gl-button
          category="tertiary"
          variant="confirm"
          class="gl-w-full"
          data-testid="board-lane-load-more-issues-button"
          @click="fetchMoreUnassignedIssues()"
        >
          {{ s__('Board|Load more issues') }}
        </gl-button>
      </div>
      <!-- placeholder for some space below lane lists -->
      <div v-else class="gl-pb-5"></div>
    </div>

    <transition name="slide" @after-enter="afterFormEnters">
      <board-add-new-column v-if="addColumnFormVisible" class="gl-sticky gl-top-5" />
    </transition>
  </div>
</template>
