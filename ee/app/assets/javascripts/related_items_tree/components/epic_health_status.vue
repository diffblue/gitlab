<script>
import { GlAlert, GlPopover, GlBadge } from '@gitlab/ui';

import { i18n } from '../constants';

export default {
  components: {
    GlAlert,
    GlPopover,
    GlBadge,
  },
  props: {
    healthStatus: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  computed: {
    hasHealthStatus() {
      const { issuesOnTrack, issuesNeedingAttention, issuesAtRisk } = this.healthStatus;
      const totalHealthStatuses = issuesOnTrack + issuesNeedingAttention + issuesAtRisk;
      return totalHealthStatuses > 0;
    },
  },
  i18n,
  badgeClasses: 'gl-ml-0! gl-mr-2 gl-font-weight-bold',
};
</script>

<template>
  <div
    v-if="hasHealthStatus"
    ref="healthStatus"
    class="health-status d-inline-flex align-items-center"
  >
    <gl-popover :target="() => $refs.healthStatus" placement="top">
      <span
        ><strong>{{ healthStatus.issuesOnTrack }}</strong
        >&nbsp;<span>{{ __('issues on track') }}</span
        >,</span
      ><br />
      <span
        ><strong>{{ healthStatus.issuesNeedingAttention }}</strong
        >&nbsp;<span>{{ __('issues need attention') }}</span
        >,</span
      ><br />
      <span
        ><strong>{{ healthStatus.issuesAtRisk }}</strong
        >&nbsp;<span>{{ __('issues at risk') }}</span></span
      >
      <gl-alert :dismissible="false" class="gl-max-w-26 gl-mt-3">
        {{ $options.i18n.permissionAlert }}
      </gl-alert>
    </gl-popover>

    <gl-badge :class="$options.badgeClasses" size="sm" variant="success">
      {{ healthStatus.issuesOnTrack }}
      <span class="gl-sr-only">&nbsp;{{ __('issues on track') }}</span>
    </gl-badge>

    <gl-badge :class="$options.badgeClasses" size="sm" variant="warning">
      {{ healthStatus.issuesNeedingAttention }}
      <span class="gl-sr-only">&nbsp;{{ __('issues need attention') }}</span>
    </gl-badge>

    <gl-badge :class="$options.badgeClasses" size="sm" variant="danger">
      {{ healthStatus.issuesAtRisk }}
      <span class="gl-sr-only">&nbsp;{{ __('issues at risk') }}</span>
    </gl-badge>
  </div>
</template>
