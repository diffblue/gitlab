<script>
import { GlFormGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { POLICY_SOURCE_OPTIONS } from '../constants';

const POLICY_SOURCE_OPTIONS_VALUES = Object.values(POLICY_SOURCE_OPTIONS);

export default {
  name: 'PolicySourceFilter',
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    value: {
      type: String,
      required: true,
      validator: (value) =>
        POLICY_SOURCE_OPTIONS_VALUES.map((option) => option.value).includes(value),
    },
  },
  computed: {
    selectedValueText() {
      return POLICY_SOURCE_OPTIONS_VALUES.find(({ value }) => value === this.value).text;
    },
  },
  methods: {
    setPolicySource(value) {
      this.$emit('input', value);
    },
  },
  policySourceFilterId: 'policy-source-filter',
  POLICY_SOURCE_OPTIONS_VALUES,
  i18n: {
    label: s__('SecurityOrchestration|Source'),
  },
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.label"
    label-size="sm"
    :label-for="$options.policySourceFilterId"
  >
    <gl-collapsible-listbox
      :id="$options.policySourceFilterId"
      block
      class="gl-display-flex"
      toggle-class="gl-truncate"
      :items="$options.POLICY_SOURCE_OPTIONS_VALUES"
      :toggle-text="selectedValueText"
      :selected="value"
      @select="setPolicySource"
    >
      <template #list-item="{ item }">
        <span :data-testid="`policy-source-${item.value}-option`">{{ item.text }}</span>
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
