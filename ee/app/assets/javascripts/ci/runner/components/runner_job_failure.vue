<script>
import { GlLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { getTypeFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';

import RunnerFullName from './runner_full_name.vue';

export default {
  name: 'RunnerJobFailure',
  components: {
    GlLink,
    TimeAgo,
    CiBadgeLink,
    RunnerFullName,
  },
  directives: {
    SafeHtml,
  },
  props: {
    job: {
      type: Object,
      required: true,
      validator(val) {
        return getTypeFromGraphQLId(val.id) === TYPENAME_CI_BUILD;
      },
    },
  },
  computed: {
    runner() {
      return this.job?.runner;
    },
    traceSummary() {
      return this.job.trace?.htmlSummary || s__('Job|No job log');
    },
  },
};
</script>
<template>
  <div>
    <time-ago v-if="job.finishedAt" :time="job.finishedAt" class="gl-text-secondary gl-font-sm" />
    <div class="gl-mt-1 gl-mb-3">
      <ci-badge-link v-if="job.detailedStatus" :status="job.detailedStatus" badge-size="sm" />
      <gl-link v-if="runner" :href="runner.adminUrl" data-testid="runner-link">
        <runner-full-name :runner="runner" />
      </gl-link>
    </div>
    <pre
      v-if="job.userPermissions.readBuild"
      class="gl-w-full gl-border-none gl-reset-bg gl-m-0 gl-p-0"
    ><code v-safe-html="traceSummary" class="gl-reset-bg gl-p-0"></code></pre>
  </div>
</template>
