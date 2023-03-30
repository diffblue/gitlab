<script>
import { GlLoadingIcon } from '@gitlab/ui';
import Draggable from 'vuedraggable';
import { mapState, mapActions } from 'vuex';
import BoardCard from '~/boards/components/board_card.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';
import eventHub from '~/boards/eventhub';
import { STATUS_CLOSED } from '~/issues/constants';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import { defaultSortableOptions } from '~/sortable/constants';
import { BoardType, EpicFilterType } from 'ee/boards/constants';

export default {
  components: {
    BoardCard,
    BoardNewIssue,
    GlLoadingIcon,
  },
  inject: ['boardType', 'fullPath', 'isApolloBoard'],
  props: {
    list: {
      type: Object,
      required: true,
    },
    issues: {
      type: Array,
      required: false,
      default: () => [],
    },
    isUnassignedIssuesLane: {
      type: Boolean,
      required: false,
      default: false,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
    epicId: {
      type: String,
      required: false,
      default: null,
    },
    boardId: {
      type: String,
      required: true,
    },
    filterParams: {
      type: Object,
      required: true,
    },
    isLoadingMoreIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showIssueForm: false,
    };
  },
  apollo: {
    currentListWithUnassignedIssues: {
      query: listsIssuesQuery,
      variables() {
        return {
          ...this.baseVariables,
          id: this.list.id,
        };
      },
      skip() {
        return !this.isApolloBoard || !this.isUnassignedIssuesLane;
      },
      context: {
        isSingleRequest: true,
      },
      update(data) {
        return data[this.boardType]?.board.lists.nodes[0];
      },
      result({ data }) {
        const list = data[this.boardType]?.board.lists.nodes[0];
        this.$emit('updatePageInfo', list.issues.pageInfo, list.id);
      },
    },
  },
  computed: {
    ...mapState([
      'activeId',
      'canAdminEpic',
      'listsFlags',
      'highlightedLists',
      'fullBoardIssuesCount',
    ]),
    baseVariables() {
      return {
        fullPath: this.fullPath,
        boardId: this.boardId,
        isGroup: this.boardType === BoardType.group,
        isProject: this.boardType === BoardType.project,
        filters: { ...this.filterParams, epicWildcardId: EpicFilterType.none.toUpperCase() },
        first: 10,
      };
    },
    issuesToUse() {
      if (this.isUnassignedIssuesLane && this.isApolloBoard) {
        return this.currentListWithUnassignedIssues?.issues.nodes || [];
      }
      return this.issues;
    },

    treeRootWrapper() {
      return this.canAdminList && (this.canAdminEpic || this.isUnassignedIssuesLane)
        ? Draggable
        : 'ul';
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableOptions,
        fallbackOnBody: false,
        group: 'board-epics-swimlanes',
        tag: 'ul',
        'ghost-class': 'board-card-drag-active',
        'data-epic-id': this.epicId,
        'data-list-id': this.list.id,
        value: this.issuesToUse,
      };

      return this.canAdminList ? options : {};
    },
    isLoading() {
      if (this.isApolloBoard) {
        return (
          this.$apollo.queries.currentListWithUnassignedIssues.loading && !this.isLoadingMoreIssues
        );
      }
      return (
        this.listsFlags[this.list.id]?.isLoading || this.listsFlags[this.list.id]?.isLoadingMore
      );
    },
    pageInfo() {
      return this.currentListWithUnassignedIssues?.issues.pageInfo || {};
    },

    highlighted() {
      return this.highlightedLists.includes(this.list.id);
    },
    boardItemsSizeExceedsMax() {
      return (
        this.list.maxIssueCount > 0 &&
        this.fullBoardIssuesCount[this.list.id] > this.list.maxIssueCount
      );
    },
    showNewIssue() {
      return this.list.type !== STATUS_CLOSED && this.showIssueForm && this.isUnassignedIssuesLane;
    },
  },
  watch: {
    filterParams: {
      handler() {
        if (this.isUnassignedIssuesLane && !this.isApolloBoard) {
          this.fetchItemsForList({ listId: this.list.id, noEpicIssues: true });
        }
      },
      deep: true,
      immediate: true,
    },
    highlighted: {
      handler(highlighted) {
        if (highlighted) {
          this.$nextTick(() => {
            this.$el.scrollIntoView(false);
          });
        }
      },
      immediate: true,
    },
    isLoadingMoreIssues(newVal) {
      if (newVal) {
        this.fetchMoreIssues();
      }
    },
  },
  created() {
    eventHub.$on(`toggle-issue-form-${this.list.id}`, this.toggleForm);
  },
  beforeDestroy() {
    eventHub.$off(`toggle-issue-form-${this.list.id}`, this.toggleForm);
  },
  methods: {
    ...mapActions(['moveIssue', 'moveIssueEpic', 'fetchItemsForList']),
    toggleForm() {
      this.showIssueForm = !this.showIssueForm;
      if (this.showIssueForm && this.isUnassignedIssuesLane) {
        this.$el.scrollIntoView(false);
      }
    },
    isActiveIssue(issue) {
      return this.activeId === issue.id;
    },
    handleDragOnStart() {
      document.body.classList.add('is-dragging');
    },
    handleDragOnEnd(params) {
      document.body.classList.remove('is-dragging');
      const { newIndex, oldIndex, from, to, item } = params;
      const { itemId, itemIid, itemPath } = item.dataset;
      const { children } = to;
      let moveBeforeId;
      let moveAfterId;

      // If issue is being moved within the same list
      if (from === to) {
        if (newIndex > oldIndex && children.length > 1) {
          // If issue is being moved down we look for the issue that ends up before
          moveBeforeId = children[newIndex].dataset.itemId;
        } else if (newIndex < oldIndex && children.length > 1) {
          // If issue is being moved up we look for the issue that ends up after
          moveAfterId = children[newIndex].dataset.itemId;
        } else {
          // If issue remains in the same list at the same position we do nothing
          return;
        }
      } else {
        // We look for the issue that ends up before the moved issue if it exists
        if (children[newIndex - 1]) {
          moveBeforeId = children[newIndex - 1].dataset.itemId;
        }
        // We look for the issue that ends up after the moved issue if it exists
        if (children[newIndex]) {
          moveAfterId = children[newIndex].dataset.itemId;
        }
      }

      this.moveIssue({
        itemId,
        itemIid,
        itemPath,
        fromListId: from.dataset.listId,
        toListId: to.dataset.listId,
        moveBeforeId,
        moveAfterId,
        epicId: from.dataset.epicId !== to.dataset.epicId ? to.dataset.epicId || null : undefined,
      });
    },
    async fetchMoreIssues() {
      await this.$apollo.queries.currentListWithUnassignedIssues.fetchMore({
        variables: { ...this.baseVariables, id: this.list.id, after: this.pageInfo.endCursor },
      });
      this.$emit('issuesLoaded');
    },
  },
};
</script>

<template>
  <div
    class="board gl-px-3 gl-vertical-align-top gl-white-space-normal gl-display-flex gl-flex-shrink-0"
    :class="{ 'is-collapsed gl-w-10': list.collapsed }"
  >
    <div class="board-inner gl-rounded-base gl-relative gl-w-full gl-bg-gray-50">
      <board-new-issue v-if="showNewIssue" :list="list" />
      <component
        :is="treeRootWrapper"
        v-if="!list.collapsed"
        v-bind="treeRootOptions"
        class="board-cell gl-p-2 gl-m-0 gl-h-full gl-list-style-none"
        :class="{
          'board-column-highlighted': highlighted,
          'gl-bg-red-100 gl-rounded-base': boardItemsSizeExceedsMax,
        }"
        data-testid="tree-root-wrapper"
        @start="handleDragOnStart"
        @end="handleDragOnEnd"
      >
        <template v-if="!isLoading">
          <board-card
            v-for="(issue, index) in issuesToUse"
            ref="issue"
            :key="issue.id"
            :index="index"
            :list="list"
            :item="issue"
            :can-admin="canAdminEpic"
          />
        </template>
        <gl-loading-icon
          v-if="(isLoading || isLoadingMoreIssues) && isUnassignedIssuesLane"
          size="sm"
          class="gl-py-3"
        />
      </component>
    </div>
  </div>
</template>
