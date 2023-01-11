<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { getPolicyListUrl, isPolicyInherited } from '../utils';
import {
  DEFAULT_DESCRIPTION_LABEL,
  DESCRIPTION_TITLE,
  ENABLED_LABEL,
  GROUP_TYPE_LABEL,
  INHERITED_LABEL,
  NOT_ENABLED_LABEL,
  PROJECT_TYPE_LABEL,
  SOURCE_TITLE,
  STATUS_TITLE,
  TYPE_TITLE,
} from './constants';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
    PolicyInfoRow,
  },
  i18n: {
    policyTypeTitle: TYPE_TITLE,
    descriptionTitle: DESCRIPTION_TITLE,
    defaultDescription: DEFAULT_DESCRIPTION_LABEL,
    sourceTitle: SOURCE_TITLE,
    statusTitle: STATUS_TITLE,
    inheritedLabel: INHERITED_LABEL,
    groupTypeLabel: GROUP_TYPE_LABEL,
    projectTypeLabel: PROJECT_TYPE_LABEL,
  },
  inject: ['namespaceType'],
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
    isInherited() {
      return isPolicyInherited(this.policy.source);
    },
    sourcePolicyListUrl() {
      return getPolicyListUrl({ namespacePath: this.policy.source.namespace.fullPath });
    },
    statusLabel() {
      return this.policy?.enabled ? ENABLED_LABEL : NOT_ENABLED_LABEL;
    },
    typeLabel() {
      if (this.namespaceType === NAMESPACE_TYPES.GROUP) {
        return this.$options.i18n.groupTypeLabel;
      }
      return this.$options.i18n.projectTypeLabel;
    },
  },
};
</script>

<template>
  <div>
    <div data-testid="policy-summary">
      <slot name="summary"></slot>
    </div>

    <policy-info-row data-testid="policy-type" :label="$options.i18n.policyTypeTitle">
      {{ type }}
    </policy-info-row>

    <policy-info-row :label="$options.i18n.descriptionTitle">
      <div v-if="description" data-testid="custom-description-text">
        {{ description }}
      </div>
      <div v-else class="gl-text-gray-500" data-testid="default-description-text">
        {{ $options.i18n.defaultDescription }}
      </div>
    </policy-info-row>

    <policy-info-row :label="$options.i18n.sourceTitle">
      <div data-testid="policy-source">
        <gl-sprintf v-if="isInherited" :message="$options.i18n.inheritedLabel">
          <template #namespace>
            <gl-link :href="sourcePolicyListUrl" target="_blank">
              {{ policy.source.namespace.name }}
            </gl-link>
          </template>
        </gl-sprintf>
        <span v-else>{{ typeLabel }}</span>
      </div>
    </policy-info-row>

    <policy-info-row :label="$options.i18n.statusTitle">
      <div v-if="policy.enabled" class="gl-text-green-500" data-testid="enabled-status-text">
        <gl-icon name="check-circle-filled" class="gl-mr-3" />{{ statusLabel }}
      </div>
      <div v-else class="gl-text-gray-500" data-testid="not-enabled-status-text">
        {{ statusLabel }}
      </div>
    </policy-info-row>
  </div>
</template>
