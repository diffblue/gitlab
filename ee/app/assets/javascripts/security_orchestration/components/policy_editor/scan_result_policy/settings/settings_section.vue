<script>
import { GlFormCheckbox, GlTooltipDirective, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

import {
  SETTINGS_HUMANISED_STRINGS,
  SETTINGS_TOOLTIP,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/settings';

export default {
  SETTINGS_HUMANISED_STRINGS,
  SETTINGS_TOOLTIP,
  i18n: {
    protectedBranchesHeader: s__('ScanResultPolicy|Protected branch settings'),
    blockUnprotectingBranches: s__(
      'ScanResultPolicy|Block users from modifying protected branches',
    ),
    protectedBranchesDescription: s__(
      'ScanResultPolicy|If selected, the following choices will overwrite %{linkStart}project settings%{linkEnd} but only affect the branches selected in the policy.',
    ),
  },
  components: {
    GlFormCheckbox,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['namespacePath', 'namespaceType'],
  props: {
    settings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    protectedBranchesDescriptionLink() {
      return joinPaths(getBaseURL(), this.namespacePath, '-', 'settings/repository');
    },
  },
  methods: {
    updateSetting(key, value) {
      const updates = { [key]: { enabled: value } };
      this.updatePolicy(updates);
    },
    updatePolicy(updates = {}) {
      this.$emit('changed', { ...this.settings, ...updates });
    },
  },
};
</script>

<template>
  <div class="gl-mb-3">
    <h5>{{ $options.i18n.protectedBranchesHeader }}</h5>
    <p>
      <gl-sprintf :message="$options.i18n.protectedBranchesDescription">
        <template #link="{ content }">
          <gl-link
            v-if="isProject"
            :href="protectedBranchesDescriptionLink"
            target="_blank"
            data-testid="protected-branches-settings-project-link"
          >
            {{ content }}</gl-link
          >
          <span v-else data-testid="protected-branches-settings-group-text">{{ content }}</span>
        </template>
      </gl-sprintf>
    </p>

    <gl-form-checkbox
      v-for="({ enabled }, key) in settings"
      :key="key"
      :checked="enabled"
      @change="updateSetting(key, $event)"
    >
      <span v-gl-tooltip.viewport.right :title="$options.SETTINGS_TOOLTIP[key]">
        {{ $options.SETTINGS_HUMANISED_STRINGS[key] }}
      </span>
    </gl-form-checkbox>
  </div>
</template>
