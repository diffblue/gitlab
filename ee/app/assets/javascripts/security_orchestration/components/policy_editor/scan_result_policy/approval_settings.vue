<script>
import { GlFormCheckbox } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    blockUnprotectingBranches: s__('ScanResultPolicy|Block users from unprotecting branches'),
  },
  components: {
    GlFormCheckbox,
  },
  props: {
    approvalSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    blockUnprotectingBranches() {
      return this.approvalSettings?.block_unprotecting_branches?.enabled || false;
    },
  },
  methods: {
    updateBlockUnprotectingBranches(value) {
      const updates = { block_unprotecting_branches: { enabled: value } };
      this.updatePolicy(updates);
    },
    updatePolicy(updates) {
      this.$emit('changed', { ...this.approvalSettings, ...updates });
    },
  },
};
</script>

<template>
  <div class="gl-mb-3">
    <gl-form-checkbox
      :checked="blockUnprotectingBranches"
      @change="updateBlockUnprotectingBranches"
    >
      {{ $options.i18n.blockUnprotectingBranches }}
    </gl-form-checkbox>
  </div>
</template>
