<script>
import { s__ } from '~/locale';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import RuleMultiSelect from 'ee/security_orchestration/components/policy_editor/rule_multi_select.vue';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';

export default {
  SEVERITY_LEVELS,
  i18n: {
    label: s__('ScanResultPolicy|Severity is:'),
    severityLevels: s__('ScanResultPolicy|severity levels'),
  },
  name: 'SeverityFilter',
  components: {
    RuleMultiSelect,
    SectionLayout,
  },
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  methods: {
    selectSeverities(states) {
      this.$emit('input', states.length > 0 ? states : null);
    },
  },
};
</script>

<template>
  <section-layout class="gl-w-full" :show-remove-button="false">
    <template #selector>
      <label class="gl-mb-0 gl-mr-2" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
      <rule-multi-select
        :value="selected"
        :item-type-name="$options.i18n.severityLevels"
        :items="$options.SEVERITY_LEVELS"
        data-testid="severities-select"
        @input="selectSeverities"
      />
    </template>
  </section-layout>
</template>
