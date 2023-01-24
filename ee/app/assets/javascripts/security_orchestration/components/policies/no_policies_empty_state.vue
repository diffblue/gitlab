<script>
import { GlEmptyState } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { NEW_POLICY_BUTTON_TEXT } from '../constants';
import { EMPTY_LIST_DESCRIPTION, EMPTY_POLICY_PROJECT_DESCRIPTION } from './constants';

export default {
  components: {
    GlEmptyState,
  },
  i18n: {
    emptyFilterTitle: s__('SecurityOrchestration|Sorry, your filter produced no results.'),
    emptyFilterDescription: s__(
      'SecurityOrchestration|To widen your search, change filters above or select a different security policy project.',
    ),
    EMPTY_LIST_DESCRIPTION,
    EMPTY_POLICY_PROJECT_DESCRIPTION,
    newPolicyButtonText: NEW_POLICY_BUTTON_TEXT,
  },
  inject: [
    'disableScanPolicyUpdate',
    'emptyFilterSvgPath',
    'emptyListSvgPath',
    'namespaceType',
    'newPolicyPath',
  ],
  props: {
    hasExistingPolicies: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasPolicyProject: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    emptyStatePrimaryButtonText() {
      return this.disableScanPolicyUpdate ? '' : this.$options.i18n.newPolicyButtonText;
    },
    emptyStateDescription() {
      return sprintf(
        this.hasPolicyProject
          ? this.$options.i18n.EMPTY_LIST_DESCRIPTION
          : this.$options.i18n.EMPTY_POLICY_PROJECT_DESCRIPTION,
        {
          namespaceType: this.namespaceType,
        },
      );
    },
  },
};
</script>
<template>
  <gl-empty-state
    v-if="hasExistingPolicies"
    key="empty-filter-state"
    data-testid="empty-filter-state"
    :svg-path="emptyFilterSvgPath"
    :title="$options.i18n.emptyFilterTitle"
    :description="$options.i18n.emptyFilterDescription"
  />
  <gl-empty-state
    v-else
    key="empty-list-state"
    data-testid="empty-list-state"
    :primary-button-link="newPolicyPath"
    :primary-button-text="emptyStatePrimaryButtonText"
    :svg-path="emptyListSvgPath"
    title=""
  >
    <template #description>
      <p class="gl-font-weight-bold">
        {{ emptyStateDescription }}
      </p>
    </template>
  </gl-empty-state>
</template>
