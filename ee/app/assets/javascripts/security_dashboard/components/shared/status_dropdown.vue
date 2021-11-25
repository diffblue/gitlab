<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import { s__ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },

  data() {
    return {
      selectedKey: null,
    };
  },

  computed: {
    dropdownPlaceholderText() {
      return this.selectedKey
        ? this.$options.states[this.selectedKey].dropdownText
        : this.$options.i18n.defaultPlaceholder;
    },
  },

  methods: {
    setSelectedKey({ state, action, payload }) {
      this.selectedKey = state;
      this.$emit('change', { action, payload });
    },
  },

  states: VULNERABILITY_STATE_OBJECTS,
  i18n: {
    defaultPlaceholder: s__('SecurityReports|Set status'),
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownPlaceholderText">
    <gl-dropdown-item
      v-for="(state, key) in $options.states"
      :key="key"
      :is-checked="selectedKey === key"
      is-check-item
      @click="setSelectedKey(state)"
    >
      <div class="gl-font-weight-bold">{{ state.dropdownText }}</div>
      <div>{{ state.dropdownDescription }}</div>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
