<script>
import { GlDropdown, GlDropdownItem, GlSprintf, GlForm } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEFAULT_SCAN, TEMPORARY_LIST_OF_SCANS } from './constants';

export default {
  SCANS: TEMPORARY_LIST_OF_SCANS,
  components: {
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
      selectedAction: this.initAction.scan || DEFAULT_SCAN,
    };
  },
  methods: {
    isSelected(key) {
      return this.selectedAction === key;
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
        <template #thenLabel="{ content }">
          <label class="text-uppercase gl-font-lg gl-mr-3">{{ content }}</label>
        </template>

        <template #scan>
          <gl-dropdown
            class="gl-mx-3"
            :text="$options.SCANS[selectedAction]"
            data-testid="action-scan"
          >
            <gl-dropdown-item
              v-for="[key, value] in Object.entries($options.SCANS)"
              :key="key"
              is-check-item
              :is-checked="isSelected(key)"
            >
              {{ value }}
            </gl-dropdown-item>
          </gl-dropdown>
        </template>
      </gl-sprintf>
    </gl-form>
  </div>
</template>
