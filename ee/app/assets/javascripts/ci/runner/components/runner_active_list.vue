<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { GlLink, GlTable, GlSkeletonLoader } from '@gitlab/ui';
import { formatNumber, s__ } from '~/locale';

import mostActiveRunnersQuery from 'ee/ci/runner/graphql/performance/most_active_runners.graphql';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { captureException } from '~/ci/runner/sentry_utils';
import { fetchPolicies } from '~/lib/graphql';
import { createAlert } from '~/alert';
import { I18N_FETCH_ERROR, JOBS_ROUTE_PATH } from '~/ci/runner/constants';
import { tableField } from '~/ci/runner/utils';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  name: 'RunnerActiveList',
  components: {
    GlLink,
    GlTable,
    CiIcon,
    GlSkeletonLoader,
  },
  data() {
    return {
      activeRunners: [],
    };
  },
  apollo: {
    activeRunners: {
      query: mostActiveRunnersQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      update({ runners }) {
        return runners?.nodes || [];
      },
      error(error) {
        createAlert({ message: I18N_FETCH_ERROR });

        captureException({ error, component: this.$options.name });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.activeRunners.loading;
    },
  },
  methods: {
    runnerSummary({ id, shortSha, description }) {
      return `#${getIdFromGraphQLId(id)} (${shortSha}) - ${description}`;
    },
    jobsUrl({ adminUrl }) {
      const url = new URL(adminUrl);
      url.hash = JOBS_ROUTE_PATH;

      return url.href;
    },
    formatNumber,
  },
  fields: [
    tableField({ key: 'index', label: '' }),
    tableField({ key: 'runner', label: s__('Runners|Runner') }),
    tableField({
      key: 'runningJobCount',
      label: s__('Runners|Running Jobs'),
      tdClass: 'gl-vertical-align-middle!',
    }),
  ],
  CI_ICON_STATUS: { group: 'running', icon: 'status_running' },
  EMPTY_STATE_SVG_URL,
};
</script>
<template>
  <div class="gl-border gl-rounded-base gl-p-5">
    <h2 class="gl-font-lg gl-mt-0">{{ s__('Runners|Active runners') }}</h2>

    <gl-table
      v-if="loading || activeRunners.length"
      :busy="loading"
      :fields="$options.fields"
      :items="activeRunners"
    >
      <template #table-busy>
        <gl-skeleton-loader :lines="9" />
      </template>
      <template #cell(index)="{ index }">
        <span class="gl-font-size-h2 gl-text-gray-500">{{ index + 1 }}</span>
      </template>
      <template #cell(runner)="{ item = {} }">
        {{ runnerSummary(item) }}
      </template>
      <template #cell(runningJobCount)="{ item = {}, value }">
        <gl-link :href="jobsUrl(item)">
          <ci-icon :status="$options.CI_ICON_STATUS" />
          {{ formatNumber(value) }}
        </gl-link>
      </template>
    </gl-table>
    <p v-else>
      {{
        s__(
          'Runners|There are no runners running jobs right now. Active runners will populate here as they pick up jobs.',
        )
      }}
    </p>
  </div>
</template>

<style scoped>
table::v-deep tr:first-child th {
  border-top: none;
}
table::v-deep tr:last-child td {
  border-bottom: none;
}
</style>
