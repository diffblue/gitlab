<script>
import {
  GlIcon,
  GlButton,
  GlLoadingIcon,
  GlTooltipDirective as GlTooltip,
  GlDropdownItem,
  GlDropdown,
  GlDropdownDivider,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { healthStatusTextMap, I18N_DROPDOWN } from '../../constants';

export default {
  directives: {
    GlTooltip,
  },
  components: {
    GlIcon,
    GlButton,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  mixins: [Tracking.mixin()],
  props: {
    isOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    canRemoveStatus() {
      return this.isEditable && this.status;
    },
    statusText() {
      return this.status ? healthStatusTextMap[this.status] : this.$options.i18n.noneText;
    },
    dropdownText() {
      return this.status
        ? healthStatusTextMap[this.status]
        : this.$options.i18n.selectPlaceholderText;
    },
    statusTooltip() {
      let tooltipText = s__('Sidebar|Health status');

      if (this.status) {
        tooltipText += `: ${this.statusText}`;
      }

      return {
        title: tooltipText,
      };
    },
    editTooltip() {
      const tooltipText = !this.isOpen
        ? s__('Health status cannot be edited because this issue is closed')
        : '';

      return {
        title: tooltipText,
        offset: -80,
      };
    },
  },
  watch: {
    status(status) {
      this.selectedStatus = status;
    },
  },
  mounted() {
    document.addEventListener('click', this.handleOffClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleOffClick);
  },
  methods: {
    handleDropdownClick(status) {
      this.selectedStatus = status;
      this.$emit('onDropdownClick', status);
      this.track('change_health_status', { property: status });
      this.hideDropdown();
    },
    hideDropdown() {
      this.isDropdownShowing = false;
    },
    toggleFormDropdown() {
      this.isDropdownShowing = !this.isDropdownShowing;

      /**
       * We need to programmatically open the dropdown to make the
       * outside click on document close the dropdown.
       */
      const { dropdown } = this.$refs.dropdown.$refs;

      if (dropdown && !this.isDropdownShowing) {
        dropdown.show();
      }
    },
    removeStatus() {
      this.handleDropdownClick(null);
    },
    isSelected(status) {
      return this.status === status;
    },
    handleOffClick(event) {
      if (!this.isDropdownShowing) return;

      if (!this.$refs.dropdown.$el.contains(event.target)) {
        this.toggleFormDropdown();
      }
    },
  },
  i18n: I18N_DROPDOWN,
};
</script>

<template>
  <div class="block health-status">
    <div ref="status" v-gl-tooltip.left.viewport="statusTooltip" class="sidebar-collapsed-icon">
      <gl-icon name="status-health" :size="14" />

      <gl-loading-icon v-if="isFetching" size="sm" />
      <p v-else class="collapse-truncated-title gl-px-2">{{ statusText }}</p>
    </div>

    <div class="hide-collapsed">
      <div
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-line-height-20 gl-mb-2 gl-text-gray-900"
      >
        <span data-testid="statusTitle">{{ s__('Sidebar|Health status') }}</span>
        <span
          v-if="isEditable"
          v-gl-tooltip.topleft="editTooltip"
          data-testid="editButtonTooltip"
          tabindex="0"
        >
          <gl-button
            ref="editButton"
            category="tertiary"
            size="small"
            class="edit-link btn-link-hover gl-text-gray-900!"
            :disabled="!isOpen"
            @click.stop="toggleFormDropdown"
            @keydown.esc="hideDropdown"
          >
            {{ __('Edit') }}
          </gl-button>
        </span>
      </div>

      <div
        data-testid="dropdownWrapper"
        class="dropdown"
        :class="{ show: isDropdownShowing, 'gl-display-none': !isDropdownShowing }"
      >
        <gl-dropdown
          ref="dropdown"
          class="gl-w-full"
          :header-text="$options.i18n.dropdownHeaderText"
          :text="dropdownText"
          @keydown.esc.native="hideDropdown"
          @hide="hideDropdown"
        >
          <gl-dropdown-item
            :is-check-item="true"
            :is-checked="isSelected(null)"
            @click="handleDropdownClick(null)"
          >
            {{ $options.i18n.noStatusText }}
          </gl-dropdown-item>

          <gl-dropdown-divider />

          <gl-dropdown-item
            v-for="option in statusOptions"
            :key="option.key"
            :is-check-item="true"
            :is-checked="isSelected(option.key)"
            @click="handleDropdownClick(option.key)"
          >
            {{ option.value }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <gl-loading-icon v-if="isFetching" size="sm" :inline="true" />
      <p v-else-if="!isDropdownShowing" class="value gl-m-0" :class="{ 'no-value': !status }">
        <span v-if="status" class="text-plain gl-font-weight-bold">{{ statusText }}</span>
        <span v-else>{{ $options.i18n.noneText }}</span>
      </p>
    </div>
  </div>
</template>
