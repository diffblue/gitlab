<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import BaseLayoutComponent from '../base_layout/base_layout_component.vue';
import { EXCEPT, MATCHING } from '../lib/rules';

export default {
  i18n: {
    headerText: s__('ScanResultPolicy|Choose an option'),
    label: s__('ScanResultPolicy|License is:'),
    licenseType: s__('ScanResultPolicy|Select license types'),
    matchTypeToggleText: s__('ScanResultPolicy|matching type'),
  },
  matchTypeOptions: [
    {
      value: 'true',
      text: MATCHING,
    },
    {
      value: 'false',
      text: EXCEPT,
    },
  ],
  components: {
    BaseLayoutComponent,
    GlCollapsibleListbox,
  },
  inject: ['parsedSoftwareLicenses'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    filteredLicenses() {
      if (this.searchTerm) {
        return this.parsedSoftwareLicenses.filter(({ value }) => {
          return value.toLowerCase().includes(this.searchTerm.toLowerCase());
        });
      }

      return this.parsedSoftwareLicenses;
    },
    licenseTypes: {
      get() {
        return this.initRule.license_types;
      },
      set(values) {
        this.triggerChanged({ license_types: values });
      },
    },
    matchType: {
      get() {
        return this.initRule.match_on_inclusion?.toString();
      },
      set(value) {
        this.triggerChanged({ match_on_inclusion: parseBoolean(value) });
      },
    },
    matchTypeToggleText() {
      return this.matchType ? '' : this.$options.i18n.matchTypeToggleText;
    },
    toggleText() {
      let toggleText = this.$options.i18n.licenseType;
      const selectedValues = [this.licenseTypes].flat();

      if (selectedValues.length === 1) {
        toggleText = this.parsedSoftwareLicenses.find(({ value }) => value === selectedValues[0])
          .text;
      }

      if (selectedValues.length > 1) {
        toggleText = sprintf(s__('ScanResultPolicy|%{count} licenses'), {
          count: selectedValues.length,
        });
      }

      return toggleText;
    },
  },
  methods: {
    filterList(searchTerm) {
      this.searchTerm = searchTerm;
    },
    triggerChanged(value) {
      this.$emit('changed', value);
    },
  },
};
</script>

<template>
  <base-layout-component class="gl-w-full gl-pt-3" :show-remove-button="false">
    <template #selector>
      <label class="gl-mb-0 gl-mr-4" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
      <slot>
        <gl-collapsible-listbox
          v-model="matchType"
          class="gl-display-inline! gl-w-auto gl-vertical-align-middle"
          :items="$options.matchTypeOptions"
          :toggle-text="matchTypeToggleText"
          data-testid="match-type-select"
        />
        <gl-collapsible-listbox
          v-model="licenseTypes"
          class="gl-vertical-align-middle gl-display-inline!"
          :items="filteredLicenses"
          :toggle-text="toggleText"
          searchable
          multiple
          data-testid="license-type-select"
          @search="filterList"
        />
      </slot>
    </template>
  </base-layout-component>
</template>
