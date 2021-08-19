<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NEW_POLICY_BUTTON_TEXT } from '../constants';

export default {
  components: {
    GlEmptyState,
  },
  i18n: {
    emptyFilterTitle: s__(`SecurityOrchestration|Sorry, your filter produced no results`),
    emptyFilterDescription: s__(
      `SecurityOrchestration|To widen your search, change filters above or select a different security policy project.`,
    ),
    emptyStateDescription: s__(
      `SecurityOrchestration|This project does not contain any security policies`,
    ),
    newPolicyButtonText: NEW_POLICY_BUTTON_TEXT,
  },
  inject: ['emptyFilterSvgPath', 'emptyListSvgPath', 'newPolicyPath'],
  props: {
    hasExistingPolicies: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div>
    <gl-empty-state
      v-if="hasExistingPolicies"
      data-testid="empty-filter-state"
      :svg-path="emptyFilterSvgPath"
      :title="$options.i18n.emptyFilterTitle"
    >
      <template #description>
        {{ $options.i18n.emptyFilterDescription }}
      </template>
    </gl-empty-state>
    <gl-empty-state
      v-else
      data-testid="empty-list-state"
      :primary-button-link="newPolicyPath"
      :primary-button-text="$options.i18n.newPolicyButtonText"
      :svg-path="emptyListSvgPath"
      title=""
    >
      <template #description>
        <p class="gl-font-weight-bold">
          {{ $options.i18n.emptyStateDescription }}
        </p>
      </template>
    </gl-empty-state>
  </div>
</template>
