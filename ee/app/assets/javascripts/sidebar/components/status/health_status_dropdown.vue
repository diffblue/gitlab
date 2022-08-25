<script>
import { GlDropdownItem, GlDropdown, GlDropdownDivider } from '@gitlab/ui';
import { healthStatusTextMap, I18N_DROPDOWN } from '../../constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  props: {
    isEditable: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isDropdownShowing: false,
      selectedStatus: this.status,
      statusOptions: Object.keys(healthStatusTextMap).map((key) => ({
        key,
        value: healthStatusTextMap[key],
      })),
    };
  },
  computed: {
    statusText() {
      return this.status ? healthStatusTextMap[this.status] : this.$options.i18n.noneText;
    },
    dropdownText() {
      if (this.status === null) {
        return this.$options.i18n.noStatusText;
      }

      return this.status
        ? healthStatusTextMap[this.status]
        : this.$options.i18n.selectPlaceholderText;
    },
  },
  watch: {
    status(status) {
      this.selectedStatus = status;
    },
  },
  methods: {
    handleDropdownClick(status) {
      this.selectedStatus = status;
      this.$emit('onDropdownClick', status);
      this.hideDropdown();
    },
    hideDropdown() {
      this.isDropdownShowing = false;
    },
    isSelected(status) {
      return this.status === status;
    },
  },
  i18n: I18N_DROPDOWN,
};
</script>

<template>
  <div class="dropdown">
    <gl-dropdown
      ref="dropdown"
      class="gl-w-full"
      :header-text="$options.i18n.dropdownHeaderText"
      :text="dropdownText"
      @keydown.esc.native="hideDropdown"
      @hide="hideDropdown"
    >
      <gl-dropdown-item
        is-check-item
        :is-checked="isSelected(null)"
        @click="handleDropdownClick(null)"
      >
        {{ $options.i18n.noStatusText }}
      </gl-dropdown-item>

      <gl-dropdown-divider />

      <gl-dropdown-item
        v-for="option in statusOptions"
        :key="option.key"
        is-check-item
        :is-checked="isSelected(option.key)"
        data-testid="health-status-dropdown-item"
        @click="handleDropdownClick(option.key)"
      >
        {{ option.value }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
