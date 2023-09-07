<script>
import { GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

export default {
  i18n: {
    preventBranchModification: s__('ScanResultPolicy|Prevent branch protection modification'),
    protectedBranchesHeader: s__('ScanResultPolicy|Protected branch settings'),
    protectedBranchesDescription: s__(
      'ScanResultPolicy|If selected, the following choices will overwrite %{linkStart}project settings%{linkEnd} but only affect the branches selected in the policy.',
    ),
  },
  components: {
    GlFormCheckbox,
    GlLink,
    GlSprintf,
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
    preventBranchModification() {
      return this.settings?.block_protected_branch_modification?.enabled || false;
    },
  },
  methods: {
    updatePreventBranchModification(value) {
      const updates = { block_protected_branch_modification: { enabled: value } };
      this.updatePolicy(updates);
    },
    updatePolicy(updates) {
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
      :checked="preventBranchModification"
      @change="updatePreventBranchModification"
    >
      {{ $options.i18n.preventBranchModification }}
    </gl-form-checkbox>
  </div>
</template>
