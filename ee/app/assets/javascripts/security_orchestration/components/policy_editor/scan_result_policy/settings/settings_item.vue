<script>
import { GlAccordionItem, GlFormCheckbox, GlTooltipDirective, GlLink, GlSprintf } from '@gitlab/ui';
import {
  SETTINGS_HUMANISED_STRINGS,
  SETTINGS_TOOLTIP,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/settings';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

export default {
  SETTINGS_HUMANISED_STRINGS,
  SETTINGS_TOOLTIP,
  name: 'SettingsItem',
  components: {
    GlAccordionItem,
    GlFormCheckbox,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['namespaceType'],
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    link: {
      type: String,
      required: false,
      default: '',
    },
    settings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    visible: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    showLink() {
      return this.isProject && Boolean(this.link);
    },
  },
  methods: {
    updateSetting(key, value) {
      this.$emit('update', { key, value });
    },
  },
};
</script>

<template>
  <gl-accordion-item :visible="visible" :title="title">
    <p v-if="description" class="gl-mb-3">
      <gl-sprintf :message="description">
        <template #link="{ content }">
          <gl-link v-if="showLink" :href="link" target="_blank" data-testid="settings-project-link">
            {{ content }}</gl-link
          >
          <span v-else data-testid="settings-group-text">{{ content }}</span>
        </template>
      </gl-sprintf>
    </p>

    <gl-form-checkbox
      v-for="({ enabled }, key) in settings"
      :key="key"
      :checked="enabled"
      @change="updateSetting(key, $event)"
    >
      <span v-gl-tooltip.viewport.right :title="$options.SETTINGS_TOOLTIP[key]">
        {{ $options.SETTINGS_HUMANISED_STRINGS[key] }}
      </span>
    </gl-form-checkbox>
  </gl-accordion-item>
</template>
