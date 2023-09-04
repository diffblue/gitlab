<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';

import {
  OPTIONS_BUTTON_LABEL,
  DELETE_BUTTON_LABEL,
  EDIT_BUTTON_LABEL,
  SET_DEFAULT_BUTTON_LABEL,
  REMOVE_DEFAULT_BUTTON_LABEL,
} from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
  },
  inject: ['canAddEdit'],
  props: {
    framework: {
      type: Object,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    optionsFramework: OPTIONS_BUTTON_LABEL,
    editFramework: EDIT_BUTTON_LABEL,
    deleteFramework: DELETE_BUTTON_LABEL,
    setDefaultFramework: SET_DEFAULT_BUTTON_LABEL,
    removeDefaultFramework: REMOVE_DEFAULT_BUTTON_LABEL,
  },
  computed: {
    isDefault() {
      return Boolean(this.framework.default);
    },
  },
  methods: {
    onEdit(event) {
      event.preventDefault();
      this.$emit('edit', this.framework);
    },
  },
};
</script>
<template>
  <div>
    <div v-if="canAddEdit" class="gl-display-flex gl-justify-content-end">
      <gl-button
        v-gl-tooltip="$options.i18n.editFramework"
        :disabled="loading"
        :aria-label="$options.i18n.editFramework"
        data-testid="compliance-framework-edit-button"
        icon="pencil"
        category="tertiary"
        @click="onEdit"
      />
      <gl-disclosure-dropdown
        v-gl-tooltip.hover.focus="$options.i18n.optionsFramework"
        category="tertiary"
        icon="ellipsis_v"
        no-caret
        placement="right"
        data-testid="compliance-framework-dropdown-button"
        :aria-label="$options.i18n.optionsFramework"
        :disabled="loading"
      >
        <template v-if="isDefault">
          <gl-disclosure-dropdown-item
            data-testid="compliance-framework-remove-default-button"
            @action="$emit('removeDefault', { framework, defaultVal: false })"
          >
            <template #list-item>
              {{ $options.i18n.removeDefaultFramework }}
            </template>
          </gl-disclosure-dropdown-item>
        </template>
        <template v-else>
          <gl-disclosure-dropdown-item
            data-testid="compliance-framework-set-default-button"
            @action="$emit('setDefault', { framework, defaultVal: true })"
          >
            <template #list-item>
              {{ $options.i18n.setDefaultFramework }}
            </template>
          </gl-disclosure-dropdown-item>
          <gl-disclosure-dropdown-item
            data-testid="compliance-framework-delete-button"
            @action="$emit('delete', framework)"
          >
            <template #list-item>
              <span class="gl-text-red-500">{{ $options.i18n.deleteFramework }}</span>
            </template>
          </gl-disclosure-dropdown-item>
        </template>
      </gl-disclosure-dropdown>
    </div>
  </div>
</template>
