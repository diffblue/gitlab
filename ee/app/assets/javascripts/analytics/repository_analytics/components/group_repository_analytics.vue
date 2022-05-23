<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import Api from '~/api';
import { helpPagePath } from '~/helpers/help_page_helper';
import { headeri18n as i18n } from '../constants';
import TestCoverageSummary from './test_coverage_summary.vue';
import TestCoverageTable from './test_coverage_table.vue';

export const VISIT_EVENT_NAME = 'i_testing_group_code_coverage_visit_total';

export default {
  name: 'GroupRepositoryAnalytics',
  components: {
    TestCoverageSummary,
    TestCoverageTable,
    GlSprintf,
    GlLink,
  },
  inject: {
    groupName: {
      default: '',
    },
  },
  mounted() {
    Api.trackRedisHllUserEvent(VISIT_EVENT_NAME);
  },
  i18n,
  learnMoreLinkPath: helpPagePath('user/group/repositories_analytics/index.md'),
};
</script>

<template>
  <div>
    <h3 class="gl-mb-5">{{ $options.i18n.title }}</h3>
    <gl-sprintf :message="$options.i18n.description">
      <template #groupName>{{ groupName }}</template>
      <template #learnMoreLink>
        <gl-link :href="$options.learnMoreLinkPath">{{ __('Learn More') }}</gl-link>
      </template>
    </gl-sprintf>

    <hr />

    <test-coverage-summary class="gl-mb-5" />
    <test-coverage-table class="gl-mb-5" />
  </div>
</template>
