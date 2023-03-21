<script>
import { GlFormInput, GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { ALL_PROTECTED_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';

export default {
  components: {
    GlFormInput,
    GlFormGroup,
    ProtectedBranchesSelector,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['namespaceId', 'namespaceType'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    groupLevelBranch: s__('SecurityOrchestration|group level branch'),
  },
  computed: {
    enteredBranches: {
      get() {
        return this.initRule.branches.length === 0 ? '*' : this.initRule.branches.join();
      },
      set(value) {
        const branches = value
          .split(',')
          .map((branch) => branch.trim())
          .filter((branch) => branch !== '*');
        this.triggerChanged({ branches });
      },
    },
    hasBranches() {
      return Boolean(this.initRule.branches.length);
    },
    branchesToAdd: {
      get() {
        return this.initRule.branches;
      },
      set(value) {
        const branches = value.id === ALL_PROTECTED_BRANCHES.id ? [] : [value.name];
        this.triggerChanged({ branches });
      },
    },
    displayBranchSelector() {
      return (
        !this.glFeatures.groupLevelScanResultPolicies ||
        NAMESPACE_TYPES.PROJECT === this.namespaceType
      );
    },
    isGroupLevelBranchesValid() {
      return this.enteredBranches.length > 0;
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
};
</script>

<template>
  <span>
    <gl-form-group class="gl-mx-3 gl-mb-3! gl-display-inline!">
      <protected-branches-selector
        v-if="displayBranchSelector"
        id="group-level-branch"
        v-model="branchesToAdd"
        :allow-all-branches-option="false"
        :allow-all-protected-branches-option="true"
        :project-id="namespaceId"
        :selected-branches-names="branchesToAdd"
      />
      <template v-else>
        <label for="group-level-branch" class="gl-sr-only">
          {{ $options.i18n.groupLevelBranch }}
        </label>
        <gl-form-input
          id="group-level-branch"
          v-model="enteredBranches"
          :state="isGroupLevelBranchesValid"
          type="text"
          data-testid="group-level-branch"
        />
      </template>
    </gl-form-group>
    <span v-if="hasBranches" data-testid="branches-label">
      {{ s__('SecurityOrchestration|branch') }}
    </span>
  </span>
</template>
