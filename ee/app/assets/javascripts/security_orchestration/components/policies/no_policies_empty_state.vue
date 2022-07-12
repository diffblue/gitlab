<script>
import { GlEmptyState } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { NEW_POLICY_BUTTON_TEXT } from '../constants';

export default {
  components: {
    GlEmptyState,
  },
  i18n: {
    emptyFilterTitle: s__('SecurityOrchestration|Sorry, your filter produced no results.'),
    emptyFilterDescription: s__(
      'SecurityOrchestration|To widen your search, change filters above or select a different security policy project.',
    ),
    emptyStateDescription: s__(
      'SecurityOrchestration|This %{namespaceType} does not contain any security policies.',
    ),
    newPolicyButtonText: NEW_POLICY_BUTTON_TEXT,
  },
  inject: ['emptyFilterSvgPath', 'emptyListSvgPath', 'namespaceType', 'newPolicyPath'],
  props: {
    hasExistingPolicies: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    description() {
      return sprintf(this.$options.i18n.emptyStateDescription, {
        namespaceType: this.namespaceType,
      });
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
    :primary-button-text="$options.i18n.newPolicyButtonText"
    :svg-path="emptyListSvgPath"
    title=""
  >
    <template #description>
      <p class="gl-font-weight-bold">
        {{ description }}
      </p>
    </template>
  </gl-empty-state>
</template>
