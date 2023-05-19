<script>
import { GlSkeletonLoader, GlTableLite, GlIcon, GlLink } from '@gitlab/ui';
import { range } from 'lodash';
import { s__, __ } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import SectionedPercentageBar from '~/usage_quotas/components/sectioned_percentage_bar.vue';
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
  components: { GlSkeletonLoader, GlTableLite, GlIcon, GlLink, SectionedPercentageBar },
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
          id: EGRESS_TYPE_ARTIFACTS,
          label: __('Artifacts'),
          description: s__('UsageQuota|Pipeline artifacts and job artifacts, created with CI/CD.'),
          icon: 'disk',
          helpPath: helpPagePath('ci/caching/index', {
            anchor: 'artifacts',
          }),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_ARTIFACTS]),
          value: this.egressTypesCombined[EGRESS_TYPE_ARTIFACTS],
          formattedValue: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_ARTIFACTS]),
        },
        {
          id: EGRESS_TYPE_REPOSITORY,
          label: __('Repository'),
          description: s__('UsageQuota|Git repository.'),
          icon: 'infrastructure-registry',
          helpPath: helpPagePath('user/project/repository/reducing_the_repo_size_using_git'),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_REPOSITORY]),
          value: this.egressTypesCombined[EGRESS_TYPE_REPOSITORY],
          formattedValue: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_REPOSITORY]),
        },
        {
          id: EGRESS_TYPE_PACKAGES,
          label: __('Packages'),
          description: s__('UsageQuota|Code packages and container images.'),
          icon: 'package',
          helpPath: helpPagePath('user/packages/package_registry/index'),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_PACKAGES]),
          value: this.egressTypesCombined[EGRESS_TYPE_PACKAGES],
          formattedValue: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_PACKAGES]),
        },
        {
          id: EGRESS_TYPE_REGISTRY,
          label: s__('UsageQuota|Registry'),
          description: s__(
            'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
          ),
          icon: 'disk',
          helpPath: helpPagePath(
            'user/packages/container_registry/reduce_container_registry_storage',
          ),
          humanSize: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_REGISTRY]),
          value: this.egressTypesCombined[EGRESS_TYPE_REGISTRY],
          formattedValue: numberToHumanSize(this.egressTypesCombined[EGRESS_TYPE_REGISTRY]),
        },
      ].filter((egressType) => egressType.value > 0);
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
    combineEgressNodes(egressType) {
      return this.egressNodes.reduce((accumulator, egressNode) => {
        return accumulator + Number(egressNode[egressType] || '0');
      }, 0);
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
      <sectioned-percentage-bar
        v-if="egressTypeSections.length"
        class="gl-mt-5"
        :sections="egressTypeSections"
      />
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
