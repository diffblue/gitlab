<script>
import { GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { sprintf, n__, s__ } from '~/locale';
import { STAT_ERROR_PLACEHOLDER } from '../constants';
import groupReleaseStatsQuery from '../graphql/group_release_stats.query.graphql';

export default {
  name: 'ReleaseStatsCard',
  components: {
    GlCard,
    GlSkeletonLoader,
  },
  inject: {
    groupPath: {
      default: '',
    },
  },
  apollo: {
    rawStats: {
      query: groupReleaseStatsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        return data.group?.stats?.releaseStats || {};
      },
      error(error) {
        this.errored = true;

        createAlert({
          message: s__('CICDAnalytics|Something went wrong while fetching release statistics'),
          captureError: true,
          error,
        });
      },
    },
  },
  data() {
    return {
      errored: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.rawStats.loading;
    },
    releasesCountStat() {
      if (this.errored) {
        return STAT_ERROR_PLACEHOLDER;
      }

      return this.rawStats?.releasesCount.toString() || '';
    },
    releasesPercentageStat() {
      if (this.errored) {
        return STAT_ERROR_PLACEHOLDER;
      }

      if (this.rawStats?.releasesPercentage != null) {
        return sprintf(s__('CICDAnalytics|%{percent}%{percentSymbol}'), {
          percent: this.rawStats?.releasesPercentage,
          percentSymbol: '%',
        });
      }

      return '';
    },
    formattedStats() {
      return [
        {
          id: 'releases-count',
          stat: this.releasesCountStat,
          title: n__(
            'CICDAnalytics|Release',
            'CICDAnalytics|Releases',
            this.rawStats?.releasesCount || 0,
          ),
        },
        {
          id: 'releases-percentage',
          stat: this.releasesPercentageStat,
          title: s__('CICDAnalytics|Projects with releases'),
        },
      ];
    },
  },
};
</script>
<template>
  <gl-card data-testid="release-stats-card">
    <template #header>
      <header class="gl-display-flex gl-align-items-baseline">
        <h1 class="gl-m-0 gl-mr-5 gl-font-lg">{{ s__('CICDAnalytics|Releases') }}</h1>
        <h2 class="gl-m-0 gl-font-base gl-text-gray-500 gl-font-weight-normal">
          {{ s__('CICDAnalytics|All time') }}
        </h2>
      </header>
    </template>

    <div
      class="gl-display-flex gl-flex-direction-column gl-flex-direction-column gl-sm-flex-direction-row"
      data-testid="stats-container"
    >
      <div
        v-for="(stat, index) of formattedStats"
        :key="stat.id"
        class="gl-flex-grow-1 gl-h-11 gl-flex-basis-0 gl-display-flex gl-align-items-center gl-flex-direction-column"
        :class="{ 'gl-xs-mb-4': index != formattedStats.length - 1 }"
      >
        <gl-skeleton-loader v-if="isLoading">
          <rect x="0" y="21" rx="3" ry="3" width="400" height="48" />
          <rect x="50" y="94" rx="3" ry="3" width="300" height="31" />
        </gl-skeleton-loader>
        <template v-else>
          <span class="gl-font-size-h-display gl-line-height-42">{{ stat.stat }}</span>
          {{ stat.title }}
        </template>
      </div>
    </div>
  </gl-card>
</template>
