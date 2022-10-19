<script>
import { GlDropdown, GlDropdownDivider, GlDropdownItem } from '@gitlab/ui';
import {
  HEALTH_STATUS_I18N_ASSIGN_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_I18N_SELECT_HEALTH_STATUS,
  healthStatusDropdownOptions,
  healthStatusTextMap,
} from '../../constants';

export default {
  HEALTH_STATUS_I18N_ASSIGN_HEALTH_STATUS,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_I18N_SELECT_HEALTH_STATUS,
  healthStatusDropdownOptions,
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
  },
  props: {
    /**
     * `null` represents a user's choice to remove the health status.
     * `undefined` represents no chosen value.
     */
    healthStatus: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    dropdownText() {
      if (this.healthStatus === null) {
        return this.$options.HEALTH_STATUS_I18N_NO_STATUS;
      }
      return this.healthStatus
        ? healthStatusTextMap[this.healthStatus]
        : this.$options.HEALTH_STATUS_I18N_SELECT_HEALTH_STATUS;
    },
  },
  methods: {
    handleClick(healthStatus) {
      this.$emit('change', healthStatus);
    },
    isSelected(healthStatus) {
      return this.healthStatus === healthStatus;
    },
    show() {
      this.$refs.dropdown.show();
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    block
    :header-text="$options.HEALTH_STATUS_I18N_ASSIGN_HEALTH_STATUS"
    :text="dropdownText"
  >
    <gl-dropdown-item is-check-item :is-checked="isSelected(null)" @click="handleClick(null)">
      {{ $options.HEALTH_STATUS_I18N_NO_STATUS }}
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <gl-dropdown-item
      v-for="option in $options.healthStatusDropdownOptions"
      :key="option.value"
      is-check-item
      :is-checked="isSelected(option.value)"
      @click="handleClick(option.value)"
    >
      {{ option.text }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
