<script>
import { GlEmptyState, GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

import { TestCaseStates, FilterStateEmptyMessage } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
    GlSprintf,
    GlLink,
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
        : __(
            'With test cases, you can define conditions for your project to meet in determining quality',
          );
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
        <gl-sprintf
          :message="
            __(
              'You can group test cases using labels. To learn about the future direction of this feature, visit %{linkStart}Quality Management direction page%{linkEnd}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://about.gitlab.com/direction/plan/#quality-management"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
      <template v-if="canCreateTestCase && showDescription" #actions>
        <gl-button :href="testCaseNewPath" category="primary" variant="confirm">{{
          __('New test case')
        }}</gl-button>
      </template>
    </gl-empty-state>
  </div>
</template>
