<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
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
    GlCollapsibleListbox,
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
  data() {
    return {
      selected: this.healthStatus === null ? '' : this.healthStatus,
    };
  },
  computed: {
    items() {
      return [
        {
          text: '',
          options: [{ text: this.$options.HEALTH_STATUS_I18N_NO_STATUS, value: '' }],
          textSrOnly: true,
        },
        {
          text: __('Health status'),
          options: this.$options.healthStatusDropdownOptions,
          textSrOnly: true,
        },
      ];
    },
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
    onSelect(value) {
      this.$emit('change', value === '' ? null : value);
    },
    show() {
      this.$refs.dropdown.open();
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    ref="dropdown"
    v-model="selected"
    block
    :header-text="$options.HEALTH_STATUS_I18N_ASSIGN_HEALTH_STATUS"
    :toggle-text="dropdownText"
    :items="items"
    @select="onSelect"
  />
</template>
