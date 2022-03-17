<script>
import { GlEmptyState, GlLink, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { i18n } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlIcon,
  },
  inject: ['testRunsEmptyStateImagePath'],
  testRunsHelpPath: helpPagePath('ci/pipelines/settings', {
    anchor: 'add-test-coverage-results-to-a-merge-request',
  }),
  i18n,
};
</script>
<template>
  <div>
    <gl-empty-state compact :svg-path="testRunsEmptyStateImagePath" class="gl-align-items-center">
      <template #title>
        <h5 class="gl-display-block gl-font-lg gl-my-4">
          {{ $options.i18n.testRuns.title }}
        </h5>
      </template>
      <template #description>
        {{ $options.i18n.testRuns.emptyStateDescription }}
      </template>
      <template #actions>
        <gl-link
          :href="$options.testRunsHelpPath"
          target="_blank"
          rel="noopener noreferrer"
          :aria-label="$options.i18n.testRuns.emptyStateLinkLabel"
          >{{ $options.i18n.testRuns.emptyStateLink }}
          <gl-icon name="external-link" />
        </gl-link>
      </template>
    </gl-empty-state>
  </div>
</template>
