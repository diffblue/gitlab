<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import IssueFieldDropdown from './issue_field_dropdown.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    IssueFieldDropdown,
    SidebarEditableItem,
  },
  provide() {
    return {
      isClassicSidebar: true,
      canUpdate: this.canUpdate,
    };
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    dropdownEmpty: {
      type: String,
      required: false,
      default: null,
    },
    dropdownTitle: {
      type: String,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    updating: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    tooltipProps() {
      return {
        boundary: 'viewport',
        placement: 'left',
        title: this.value || this.title,
      };
    },
    valueWithFallback() {
      return this.value || this.$options.i18n.none;
    },
    valueClass() {
      return {
        'no-value': !this.value,
      };
    },
  },
  i18n: {
    none: __('None'),
  },
  methods: {
    showDropdown() {
      this.$refs.dropdown.showDropdown();
      this.$emit('issue-field-fetch');
    },
    expandSidebarAndOpenDropdown() {
      this.$emit('expand-sidebar', this.$refs.editableItem);
    },
    onIssueFieldUpdated(value) {
      this.$emit('issue-field-updated', value);
    },
  },
};
</script>

<template>
  <div class="block">
    <sidebar-editable-item
      ref="editableItem"
      :loading="updating"
      :title="title"
      @open="showDropdown"
    >
      <template #collapsed>
        <div
          v-gl-tooltip="tooltipProps"
          class="sidebar-collapsed-icon"
          data-testid="field-collapsed"
          @click="expandSidebarAndOpenDropdown"
        >
          <gl-icon :name="icon" />
        </div>

        <div class="hide-collapsed">
          <div class="value" data-testid="field-value">
            <span :class="valueClass">{{ valueWithFallback }}</span>
          </div>
        </div>
      </template>

      <template #default>
        <issue-field-dropdown
          v-if="canUpdate"
          ref="dropdown"
          :empty-text="dropdownEmpty"
          :items="items"
          :loading="loading"
          :text="valueWithFallback"
          :title="dropdownTitle"
          @issue-field-updated="onIssueFieldUpdated"
        />
      </template>
    </sidebar-editable-item>
  </div>
</template>
