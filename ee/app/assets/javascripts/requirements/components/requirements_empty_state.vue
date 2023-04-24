<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

import { FilterState, filterStateEmptyMessage } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    emptyStatePath: {
      type: String,
      required: true,
    },
    requirementsCount: {
      type: Object,
      required: true,
    },
    canCreateRequirement: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return this.requirementsCount[FilterState.all]
        ? filterStateEmptyMessage[this.filterBy]
        : __('With requirements, you can set criteria to check your products against.');
    },
    emptyStateDescription() {
      return !this.requirementsCount[FilterState.all]
        ? __(
            `Requirements can be based on users, stakeholders, system, software,
            or anything else you find important to capture.`,
          )
        : null;
    },
  },
};
</script>

<template>
  <div class="requirements-empty-state-container">
    <gl-empty-state
      :svg-path="emptyStatePath"
      :title="emptyStateTitle"
      :description="emptyStateDescription"
    >
      <template v-if="emptyStateDescription && canCreateRequirement" #actions>
        <gl-button category="primary" variant="confirm" @click="$emit('click-new-requirement')">{{
          __('New requirement')
        }}</gl-button>
        <gl-button
          category="secondary"
          variant="default"
          @click="$emit('click-import-requirements')"
        >
          {{ __('Import requirements') }}
        </gl-button>
      </template>
    </gl-empty-state>
  </div>
</template>
