<script>
import { GlSkeletonLoader, GlTableLite, GlLink, GlIcon } from '@gitlab/ui';
import { range } from 'lodash';
import { s__, __ } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { roundOffFloat } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  EGRESS_TYPE_ARTIFACTS,
  EGRESS_TYPE_REPOSITORY,
  EGRESS_TYPE_PACKAGES,
  EGRESS_TYPE_REGISTRY,
  EGRESS_TYPE_TOTAL,
  EGRESS_TYPES,
} from '../constants';

export default {
  i18n: {
    title: s__('UsageQuota|Transfer usage breakout'),
    description: s__(
      'UsageQuota|Includes project artifacts, repositories, packages, and container registries.',
    ),
  },
  fields: [
    {
      key: 'transferType',
      label: s__('UsageQuota|Transfer type'),
      tdClass: ['gl-w-full gl-overflow-wrap-anywhere'],
      thClass: ['gl-w-full'],
    },
    {
      key: 'dataUsed',
      label: s__('UsageQuota|Transfer data used'),
      tdClass: ['gl-white-space-nowrap gl-vertical-align-middle!'],
      thClass: ['gl-white-space-nowrap'],
    },
  ],
  components: { GlSkeletonLoader, GlTableLite, GlLink, GlIcon },
  props: {
    egressNodes: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    egressTypesCombined() {
      return EGRESS_TYPES.reduce(
        (accumulator, egressType) => ({
          ...accumulator,
          [egressType]: this.combineEgressNodes(egressType),
        }),
        {},
      );
    },
    egressTypeSections() {
      if (this.egressTypesCombined[EGRESS_TYPE_TOTAL] === 0) {
        return [];
      }

      return [
        {
          type: EGRESS_TYPE_ARTIFACTS,
          label: __('Artifacts'),
          description: s__('UsageQuota|Pipeline artifacts and job artifacts, created with CI/CD.'),
          icon: 'disk',
          helpPath: helpPagePath('ci/caching/index', {
            anchor: 'artifacts',
          }),
          percentage: this.calculatePercentage(EGRESS_TYPE_ARTIFACTS),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_ARTIFACTS]),
          cssClasses: 'gl-bg-data-viz-blue-500',
        },
        {
          type: EGRESS_TYPE_REPOSITORY,
          label: __('Repository'),
          description: s__('UsageQuota|Git repository.'),
          icon: 'infrastructure-registry',
          helpPath: helpPagePath('user/project/repository/reducing_the_repo_size_using_git'),
          percentage: this.calculatePercentage(EGRESS_TYPE_REPOSITORY),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_REPOSITORY]),
          cssClasses: 'gl-bg-data-viz-orange-500',
        },
        {
          type: EGRESS_TYPE_PACKAGES,
          label: __('Packages'),
          description: s__('UsageQuota|Code packages and container images.'),
          icon: 'package',
          helpPath: helpPagePath('user/packages/package_registry/index'),
          percentage: this.calculatePercentage(EGRESS_TYPE_PACKAGES),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_PACKAGES]),
          cssClasses: 'gl-bg-data-viz-aqua-500',
        },
        {
          type: EGRESS_TYPE_REGISTRY,
          label: s__('UsageQuota|Registry'),
          description: s__(
            'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
          ),
          icon: 'disk',
          helpPath: helpPagePath(
            'user/packages/container_registry/reduce_container_registry_storage',
          ),
          percentage: this.calculatePercentage(EGRESS_TYPE_REGISTRY),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_REGISTRY]),
          cssClasses: 'gl-bg-data-viz-green-500',
        },
      ].filter((egressType) => egressType.percentage > 0);
    },
    totalEgressCombinedHumanSize() {
      return numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_TOTAL]);
    },
    tableItems() {
      if (this.loading) {
        return range(4).map(() => ({}));
      }

      return this.egressTypeSections;
    },
  },
  methods: {
    percentageAsString(percentage, precision) {
      return `${roundOffFloat(percentage, precision)}%`;
    },
    combineEgressNodes(egressType) {
      return this.egressNodes.reduce((accumulator, egressNode) => {
        return accumulator + Number(egressNode[egressType] || '0');
      }, 0);
    },
    calculatePercentage(egressType) {
      return (
        (this.egressTypesCombined[egressType] / this.egressTypesCombined[EGRESS_TYPE_TOTAL]) * 100
      );
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <template v-if="loading">
      <div class="gl-lg-w-half">
        <gl-skeleton-loader :height="50">
          <rect width="140" height="30" x="0" y="0" rx="4" />
          <rect width="240" height="10" x="0" y="40" rx="4" />
        </gl-skeleton-loader>
      </div>
      <div class="gl-w-full gl-mt-5">
        <gl-skeleton-loader :height="16" :width="1248">
          <rect x="0" y="0" rx="12" ry="12" width="1248" height="16" />
        </gl-skeleton-loader>
      </div>
    </template>
    <template v-else>
      <div class="gl-display-flex gl-justify-content-space-between">
        <div>
          <h4 class="gl-font-lg gl-mb-3 gl-mt-0">{{ $options.i18n.title }}</h4>
          <p>{{ $options.i18n.description }}</p>
        </div>
        <p
          class="gl-m-0 gl-font-size-h-display gl-font-weight-bold gl-white-space-nowrap"
          data-testid="total-egress"
        >
          {{ totalEgressCombinedHumanSize }}
        </p>
      </div>
      <div
        v-if="egressTypeSections.length"
        class="gl-display-flex gl-rounded-pill gl-overflow-hidden gl-mt-5 gl-w-full"
        data-testid="percentage-bar"
      >
        <div
          v-for="{ type, label, cssClasses, percentage } in egressTypeSections"
          :key="type"
          class="gl-h-5"
          :class="cssClasses"
          :style="{
            width: percentageAsString(percentage, 4),
          }"
          :data-testid="`percentage-bar-egress-type-${type}`"
        >
          <span class="gl-sr-only">{{ label }} {{ percentageAsString(percentage, 1) }}</span>
        </div>
      </div>
      <div class="gl-mt-5">
        <div class="gl-display-flex gl-align-items-center gl-flex-wrap gl-my-n3 gl-mx-n3">
          <div
            v-for="{ type, label, cssClasses, humanSize } in egressTypeSections"
            :key="type"
            class="gl-display-flex gl-align-items-center gl-p-3"
            :data-testid="`percentage-bar-legend-egress-type-${type}`"
          >
            <div class="gl-h-2 gl-w-5 gl-mr-2 gl-display-inline-block" :class="cssClasses"></div>
            <p class="gl-m-0 gl-font-sm">
              <span class="gl-mr-2 gl-font-weight-bold">
                {{ label }}
              </span>
              <span class="gl-text-gray-500">
                {{ humanSize }}
              </span>
            </p>
          </div>
        </div>
      </div>
    </template>
    <gl-table-lite :fields="$options.fields" :items="tableItems" class="gl-mt-7">
      <template #cell(transferType)="{ item: { label, description, icon, helpPath } }">
        <div v-if="loading" class="gl-w-20">
          <gl-skeleton-loader :width="120" :height="16">
            <rect x="0" y="0" rx="2" ry="2" width="120" height="16" />
          </gl-skeleton-loader>
        </div>
        <div
          v-else
          class="gl-display-flex gl-flex-direction-row"
          data-testid="transfer-type-column"
        >
          <gl-icon :name="icon" class="gl-mr-4 gl-flex-shrink-0" />
          <div>
            <p class="gl-font-weight-bold gl-mb-0">
              {{ label }}
              <gl-link :href="helpPath" target="_blank">
                <gl-icon name="question-o" :size="12" />
              </gl-link>
            </p>
            <p class="gl-mb-0">
              {{ description }}
            </p>
          </div>
        </div>
      </template>

      <template #cell(dataUsed)="{ item: { humanSize } }">
        <div v-if="loading" class="gl-w-12">
          <gl-skeleton-loader :width="80" :height="16">
            <rect x="0" y="0" rx="2" ry="2" width="80" height="16" />
          </gl-skeleton-loader>
        </div>
        <span v-else data-testid="usage-column">{{ humanSize }}</span>
      </template>
    </gl-table-lite>
  </div>
</template>
