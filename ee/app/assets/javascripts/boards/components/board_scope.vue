<script>
import { __ } from '~/locale';
import AssigneeSelect from './assignee_select.vue';
import BoardLabelsSelect from './labels_select.vue';
import BoardIterationSelect from './iteration_select.vue';
import BoardMilestoneSelect from './milestone_select.vue';
import BoardWeightSelect from './weight_select.vue';

export default {
  components: {
    AssigneeSelect,
    BoardLabelsSelect,
    BoardIterationSelect,
    BoardMilestoneSelect,
    BoardWeightSelect,
  },
  inject: ['isIssueBoard'],
  props: {
    collapseScope: {
      type: Boolean,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    board: {
      type: Object,
      required: true,
    },
    weights: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  data() {
    return {
      expanded: false,
    };
  },

  computed: {
    expandButtonText() {
      return this.expanded ? __('Collapse') : __('Expand');
    },
    scopeText() {
      return this.isIssueBoard
        ? __('Board scope affects which issues are displayed for anyone who visits this board')
        : __('Board scope affects which epics are displayed for anyone who visits this board');
    },
    iterationId() {
      return this.board.iteration?.id;
    },
  },

  methods: {
    handleLabelClick(labels) {
      this.$emit('set-board-labels', labels);
    },
    handleLabelRemove(labelId) {
      const labelToRemove = [{ id: labelId, set: false }];
      this.handleLabelClick(labelToRemove);
    },
  },
};
</script>

<template>
  <div data-qa-selector="board_scope_modal">
    <div v-if="canAdminBoard" class="media">
      <label class="label-bold gl-font-lg media-body">{{ __('Scope') }}</label>
      <button v-if="collapseScope" type="button" class="btn" @click="expanded = !expanded">
        {{ expandButtonText }}
      </button>
    </div>
    <p class="text-secondary gl-mb-3">
      {{ scopeText }}
    </p>
    <div v-if="!collapseScope || expanded">
      <board-milestone-select
        v-if="isIssueBoard"
        :board="board"
        :can-edit="canAdminBoard"
        @set-milestone="$emit('set-milestone', $event)"
      />

      <board-iteration-select
        v-if="isIssueBoard"
        :board="board"
        :can-edit="canAdminBoard"
        @set-iteration="$emit('set-iteration', $event)"
      />

      <board-labels-select
        :board="board"
        :can-edit="canAdminBoard"
        @onLabelRemove="handleLabelRemove"
        @set-labels="handleLabelClick"
      />

      <assignee-select
        v-if="isIssueBoard"
        :board="board"
        :can-edit="canAdminBoard"
        @set-assignee="$emit('set-assignee', $event)"
      />

      <board-weight-select
        v-if="isIssueBoard"
        :board="board"
        :weights="weights"
        :can-edit="canAdminBoard"
        @set-weight="$emit('set-weight', $event)"
      />
    </div>
  </div>
</template>
