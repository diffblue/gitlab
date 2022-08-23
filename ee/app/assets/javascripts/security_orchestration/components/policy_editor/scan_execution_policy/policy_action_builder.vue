<script>
import { GlButton, GlDropdown, GlDropdownItem, GlSprintf, GlForm } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTION_THEN_LABEL, ACTION_AND_LABEL } from '../constants';
import { DEFAULT_SCANNER, TEMPORARY_LIST_OF_SCANNERS } from './constants';
import { buildScannerAction } from './lib';

export default {
  SCANNERS: TEMPORARY_LIST_OF_SCANNERS,
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlForm,
    GlSprintf,
  },
  props: {
    initAction: {
      type: Object,
      required: true,
    },
    actionIndex: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      selectedAction: this.initAction.scan || DEFAULT_SCANNER,
    };
  },
  computed: {
    actionLabel() {
      return this.actionIndex === 0 ? ACTION_THEN_LABEL : ACTION_AND_LABEL;
    },
  },
  methods: {
    setSelected(key) {
      this.selectedAction = key;

      this.$emit('changed', buildScannerAction(key));
    },
  },
  i18n: {
    humanizedTemplate: s__(
      'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require a %{scan} scan to run',
    ),
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-px-5! gl-pt-5! gl-relative gl-pb-4">
    <gl-form inline @submit.prevent>
      <gl-sprintf :message="$options.i18n.humanizedTemplate">
        <template #thenLabel>
          <label class="text-uppercase gl-font-lg gl-mr-3" data-testid="action-component-label">
            {{ actionLabel }}
          </label>
        </template>

        <template #scan>
          <gl-dropdown
            class="gl-mx-3"
            :text="$options.SCANNERS[selectedAction]"
            data-testid="action-scanner-text"
          >
            <gl-dropdown-item
              v-for="(value, key) in $options.SCANNERS"
              :key="key"
              @click="setSelected(key)"
            >
              {{ value }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>
      </gl-sprintf>
    </gl-form>
    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-absolute gl-top-1 gl-right-1"
      :aria-label="__('Remove')"
      @click="$emit('remove', $event)"
    />
  </div>
</template>
