<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { SCANNER_TYPE } from 'ee/on_demand_scans/constants';

export default {
  i18n: {
    emptyStateButton: s__('OnDemandScans|New %{scannerType} profile'),
    emptyStateContent: s__(
      'OnDemandScans|Start by creating a new profile. Profiles make it easy to save and reuse configuration details for GitLab’s security tools.',
    ),
    emptyStateHeader: s__('OnDemandScans|No %{scannerType} profiles found for DAST'),
  },
  name: 'DastProfilesSidebarEmptyState',
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    profileType: {
      type: String,
      required: false,
      default: SCANNER_TYPE,
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-align-items-center">
    <h5 class="gl-text-secondary gl-mt-0 gl-mb-2" data-testid="empty-state-header">
      <gl-sprintf :message="$options.i18n.emptyStateHeader">
        <template #scannerType>
          <span>{{ profileType }}</span>
        </template>
      </gl-sprintf>
    </h5>
    <span class="gl-text-gray-500 gl-text-center">
      {{ $options.i18n.emptyStateContent }}
    </span>
    <gl-button
      class="gl-mt-5"
      variant="confirm"
      category="primary"
      data-testid="new-empty-profile-button"
      @click="$emit('click')"
    >
      <gl-sprintf :message="$options.i18n.emptyStateButton">
        <template #scannerType>
          <span>{{ profileType }}</span>
        </template>
      </gl-sprintf>
    </gl-button>
  </div>
</template>
