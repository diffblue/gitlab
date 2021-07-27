<script>
import { mapGetters } from 'vuex';
import { __ } from '~/locale';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import AssigneeSelect from './assignee_select.vue';
import BoardScopeCurrentIteration from './board_scope_current_iteration.vue';
import BoardMilestoneSelect from './milestone_select.vue';
import BoardWeightSelect from './weight_select.vue';

export default {
  components: {
    AssigneeSelect,
    LabelsSelect,
    BoardMilestoneSelect,
    BoardScopeCurrentIteration,
    BoardWeightSelect,
  },
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
    labelsPath: {
      type: String,
      required: true,
    },
    labelsWebUrl: {
      type: String,
      required: true,
    },
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectId: {
      type: Number,
      required: false,
      default: 0,
    },
    groupId: {
      type: Number,
      required: false,
      default: 0,
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
    ...mapGetters(['isIssueBoard']),
    expandButtonText() {
      return this.expanded ? __('Collapse') : __('Expand');
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
      {{ __('Board scope affects which issues are displayed for anyone who visits this board') }}
    </p>
    <div v-if="!collapseScope || expanded">
      <board-milestone-select
        v-if="isIssueBoard"
        :board="board"
        :group-id="groupId"
        :project-id="projectId"
        :can-edit="canAdminBoard"
      />

      <board-scope-current-iteration
        v-if="isIssueBoard"
        :can-admin-board="canAdminBoard"
        :iteration-id="board.iteration_id"
        @set-iteration="$emit('set-iteration', $event)"
      />

      <labels-select
        :allow-label-edit="canAdminBoard"
        :allow-label-create="canAdminBoard"
        :allow-label-remove="canAdminBoard"
        :allow-multiselect="true"
        :allow-scoped-labels="enableScopedLabels"
        :selected-labels="board.labels"
        :hide-collapsed-view="true"
        :labels-fetch-path="labelsPath"
        :labels-manage-path="labelsWebUrl"
        :labels-filter-base-path="labelsWebUrl"
        :labels-list-title="__('Select labels')"
        :dropdown-button-text="__('Choose labels')"
        variant="sidebar"
        class="block labels"
        @onLabelRemove="handleLabelRemove"
        @updateSelectedLabels="handleLabelClick"
      >
        {{ __('Any label') }}
      </labels-select>

      <assignee-select
        v-if="isIssueBoard"
        :board="board"
        :can-edit="canAdminBoard"
        :project-id="projectId"
        :group-id="groupId"
        @set-assignee="$emit('set-assignee', $event)"
      />

      <!-- eslint-disable vue/no-mutating-props -->
      <board-weight-select
        v-if="isIssueBoard"
        v-model="board.weight"
        :board="board"
        :weights="weights"
        :can-edit="canAdminBoard"
      />
      <!-- eslint-enable vue/no-mutating-props -->
    </div>
  </div>
</template>
