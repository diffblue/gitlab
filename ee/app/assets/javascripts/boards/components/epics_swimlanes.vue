<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import VirtualList from 'vue-virtual-scroll-list';
import Draggable from 'vuedraggable';
import { mapActions, mapGetters, mapState } from 'vuex';
import BoardAddNewColumn from 'ee_else_ce/boards/components/board_add_new_column.vue';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import { isListDraggable } from '~/boards/boards_util';
import eventHub from '~/boards/eventhub';
import { s__, n__, __ } from '~/locale';
import defaultSortableConfig from '~/sortable/sortable_config';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { calculateSwimlanesBufferSize } from '../boards_util';
import { DRAGGABLE_TAG, EPIC_LANE_BASE_HEIGHT } from '../constants';
import EpicLane from './epic_lane.vue';
import IssuesLaneList from './issues_lane_list.vue';
import SwimlanesLoadingSkeleton from './swimlanes_loading_skeleton.vue';

export default {
  EpicLane,
  epicLaneBaseHeight: EPIC_LANE_BASE_HEIGHT,
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
  mixins: [glFeatureFlagsMixin()],
  props: {
    lists: {
      type: Array,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      bufferSize: 0,
      isUnassignedCollapsed: true,
    };
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
    addColumnFormVisible() {
      return this.addColumnForm?.visible;
    },
    unassignedIssues() {
      return (listId) => this.getUnassignedIssues(listId);
    },
    unassignedIssuesCount() {
      return this.lists.reduce((total, list) => {
        return total + (this.listsFlags[list.id]?.unassignedIssuesCount || 0);
      }, 0);
    },
    unassignedIssuesCountTooltipText() {
      return n__(`%d unassigned issue`, `%d unassigned issues`, this.unassignedIssuesCount);
    },
    treeRootWrapper() {
      return this.canAdminList ? Draggable : DRAGGABLE_TAG;
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableConfig,
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
      return (
        this.unassignedIssuesCount > 0 &&
        this.lists.some((list) => this.pageInfoByListId[list.id]?.hasNextPage)
      );
    },
    isLoading() {
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
  },
  watch: {
    filterParams: {
      handler() {
        Promise.all(this.epics.map((epic) => this.fetchIssuesForEpic(epic.id)))
          .then(() => this.doneLoadingSwimlanesItems())
          .catch(() => {});
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
    fetchMoreEpics() {
      this.fetchEpicsSwimlanes({ fetchNext: true });
    },
    fetchMoreUnassignedIssues() {
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
        key: this.epics[index].id,
        props: {
          epic: this.epics[index],
          lists: this.lists,
          disabled: this.disabled,
          canAdminList: this.canAdminList,
        },
      };
    },
    toggleUnassignedLane() {
      this.isUnassignedCollapsed = !this.isUnassignedCollapsed;
    },
    openUnassignedLane() {
      this.isUnassignedCollapsed = false;
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
        class="board-swimlanes-headers gl-display-table gl-sticky gl-pt-5 gl-mb-5 gl-bg-white gl-top-0 gl-z-index-3"
        data-testid="board-swimlanes-headers"
        @end="moveList"
      >
        <div
          v-for="list in lists"
          :key="list.id"
          :class="{
            'is-collapsed': list.collapsed,
            'is-draggable': isListDraggable(list),
          }"
          class="board gl-display-inline-block gl-px-3 gl-vertical-align-top gl-white-space-normal"
          :data-list-id="list.id"
          data-testid="board-header-container"
        >
          <board-list-header
            :can-admin-list="canAdminList"
            :list="list"
            :disabled="disabled"
            :is-swimlanes-header="true"
          />
        </div>
      </component>
      <div class="board-epics-swimlanes gl-display-table">
        <template v-if="glFeatures.swimlanesBufferedRendering">
          <virtual-list
            v-if="epics.length"
            :size="$options.epicLaneBaseHeight"
            :remain="bufferSize"
            :bench="bufferSize"
            :scrollelement="$refs.scrollableContainer"
            :item="$options.EpicLane"
            :itemcount="epics.length"
            :itemprops="getEpicLaneProps"
          />
        </template>
        <template v-else>
          <epic-lane
            v-for="epic in epics"
            :key="epic.id"
            :epic="epic"
            :lists="lists"
            :disabled="disabled"
            :can-admin-list="canAdminList"
          />
        </template>
        <div v-if="hasMoreEpics" class="swimlanes-button gl-pb-3 gl-pl-3 gl-sticky gl-left-0">
          <gl-button
            category="tertiary"
            variant="confirm"
            class="gl-w-full"
            :loading="epicsSwimlanesFetchInProgress.epicLanesFetchMoreInProgress"
            :disabled="epicsSwimlanesFetchInProgress.epicLanesFetchMoreInProgress"
            data-testid="load-more-epics"
            data-track-action="click_button"
            data-track-label="toggle_swimlanes"
            data-track-property="click_load_more_epics"
            @click="fetchMoreEpics()"
          >
            {{ epicButtonLabel }}
          </gl-button>
        </div>
        <div class="board-lane-unassigned-issues-title gl-sticky gl-display-inline-block gl-left-0">
          <div class="gl-left-0 gl-pb-5 gl-px-3 gl-display-flex gl-align-items-center">
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
            <span
              v-if="unassignedIssuesCount > 0"
              v-gl-tooltip.hover
              :title="unassignedIssuesCountTooltipText"
              class="gl-display-flex gl-align-items-center gl-text-gray-500"
              tabindex="0"
              :aria-label="unassignedIssuesCountTooltipText"
              data-testid="issues-lane-issue-count"
            >
              <gl-icon class="gl-mr-2 gl-flex-shrink-0" name="issues" />
              <span aria-hidden="true">{{ unassignedIssuesCount }}</span>
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
              :disabled="disabled"
              :can-admin-list="canAdminList"
            />
          </div>
        </div>
      </div>
      <div
        v-if="hasMoreUnassignedIssues && !isUnassignedCollapsed"
        class="swimlanes-button gl-p-3 gl-pr-0 gl-sticky gl-left-0"
      >
        <gl-button
          category="tertiary"
          variant="confirm"
          class="gl-w-full"
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
