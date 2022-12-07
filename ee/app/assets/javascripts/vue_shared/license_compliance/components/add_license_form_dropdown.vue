<script>
import { GlFormCombobox } from '@gitlab/ui';

export default {
  name: 'AddLicenseFormDropdown',
  components: {
    GlFormCombobox,
  },
  props: {
    knownLicenses: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      licenseName: '',
    };
  },
  watch: {
    licenseName(query) {
      this.$emit('update-selected-license', query);
    },
  },
};
</script>
<template>
  <gl-form-combobox
    v-model="licenseName"
    :token-list="knownLicenses"
    :label-text="s__('LicenseCompliance|Add license and related policy')"
    :placeholder="s__('LicenseCompliance|License name')"
  />
</template>
