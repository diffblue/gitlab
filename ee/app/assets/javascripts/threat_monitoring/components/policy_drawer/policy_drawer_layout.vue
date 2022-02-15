<script>
import { GlIcon } from '@gitlab/ui';
import {
  DEFAULT_DESCRIPTION_LABEL,
  DESCRIPTION_TITLE,
  ENABLED_LABEL,
  NOT_ENABLED_LABEL,
  STATUS_TITLE,
  TYPE_TITLE,
} from './constants';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  components: {
    GlIcon,
    PolicyInfoRow,
  },
  i18n: {
    policyTypeTitle: TYPE_TITLE,
    descriptionTitle: DESCRIPTION_TITLE,
    defaultDescription: DEFAULT_DESCRIPTION_LABEL,
    statusTitle: STATUS_TITLE,
  },
  props: {
    description: {
      type: String,
      required: false,
      default: '',
    },
    policy: {
      type: Object,
      required: false,
      default: null,
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    statusLabel() {
      return this.policy?.enabled ? ENABLED_LABEL : NOT_ENABLED_LABEL;
    },
  },
};
</script>

<template>
  <div>
    <p data-testid="policy-summary">
      <slot name="summary"></slot>
    </p>

    <h5 class="gl-mt-3">{{ $options.i18n.policyTypeTitle }}</h5>
    <p data-testid="policy-type">{{ type }}</p>

    <p data-testid="policy-description">
      <policy-info-row :label="$options.i18n.descriptionTitle">
        <div v-if="description" data-testid="custom-description-text">
          {{ description }}
        </div>
        <div v-else class="gl-text-gray-500" data-testid="default-description-text">
          {{ $options.i18n.defaultDescription }}
        </div>
      </policy-info-row>
    </p>

    <p data-testid="policy-status">
      <policy-info-row :label="$options.i18n.statusTitle">
        <div v-if="policy.enabled" class="gl-text-green-500" data-testid="enabled-status-text">
          <gl-icon name="check-circle-filled" class="gl-mr-3" />{{ statusLabel }}
        </div>
        <div v-else class="gl-text-gray-500" data-testid="not-enabled-status-text">
          {{ statusLabel }}
        </div>
      </policy-info-row>
    </p>
  </div>
</template>
