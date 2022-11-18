<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

import { TestCaseStates, FilterStateEmptyMessage } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  inject: ['canCreateTestCase', 'testCaseNewPath', 'emptyStatePath'],
  props: {
    currentState: {
      type: String,
      required: true,
    },
    testCasesCount: {
      type: Object,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return this.testCasesCount[TestCaseStates.All]
        ? FilterStateEmptyMessage[this.currentState]
        : __('Improve quality with test cases');
    },
    showDescription() {
      return !this.testCasesCount[TestCaseStates.All];
    },
  },
};
</script>

<template>
  <div class="test-cases-empty-state-container">
    <gl-empty-state :svg-path="emptyStatePath" :title="emptyStateTitle">
      <template v-if="showDescription" #description>
        {{
          __(
            'Create testing scenarios by defining project conditions in your development platform.',
          )
        }}
      </template>
      <template v-if="canCreateTestCase && showDescription" #actions>
        <gl-button :href="testCaseNewPath" category="primary" variant="confirm">{{
          __('New test case')
        }}</gl-button>
      </template>
    </gl-empty-state>
  </div>
</template>
