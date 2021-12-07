<script>
import { GlEmptyState } from '@gitlab/ui';
import { IssuableStates } from '~/vue_shared/issuable/list/constants';
import { __ } from '~/locale';

import { FilterStateEmptyMessage } from '../constants';

export default {
  components: {
    GlEmptyState,
  },
  inject: ['emptyStatePath'],
  props: {
    currentState: {
      type: String,
      required: true,
    },
    epicsCount: {
      type: Object,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return this.epicsCount[IssuableStates.All]
        ? FilterStateEmptyMessage[this.currentState]
        : __(
            'Epics let you manage your portfolio of projects more efficiently and with less effort',
          );
    },
    showDescription() {
      return !this.epicsCount[IssuableStates.All];
    },
  },
};
</script>

<template>
  <gl-empty-state :svg-path="emptyStatePath" :title="emptyStateTitle">
    <template v-if="showDescription" #description>
      {{ __('Track groups of issues that share a theme, across projects and milestones') }}
    </template>
  </gl-empty-state>
</template>
