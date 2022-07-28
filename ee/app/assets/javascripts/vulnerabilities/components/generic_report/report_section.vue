<script>
import { GlCollapse, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ReportItem from './report_item.vue';
import { filterTypesAndLimitListDepth } from './types/utils';

const NESTED_LISTS_MAX_DEPTH = 4;

export default {
  i18n: {
    heading: s__('Vulnerability|Evidence'),
  },
  components: {
    GlCollapse,
    GlIcon,
    ReportItem,
  },
  props: {
    details: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showSection: true,
    };
  },
  computed: {
    filteredDetails() {
      return filterTypesAndLimitListDepth(this.details, {
        maxDepth: NESTED_LISTS_MAX_DEPTH,
      });
    },
    detailsEntries() {
      return Object.entries(this.filteredDetails);
    },
    hasDetails() {
      return this.detailsEntries.length > 0;
    },
  },
  methods: {
    toggleShowSection() {
      this.showSection = !this.showSection;
    },
  },
};
</script>
<template>
  <section v-if="hasDetails">
    <header
      class="gl-display-inline-flex gl-align-items-center gl-font-size-h3 gl-cursor-pointer"
      @click="toggleShowSection"
    >
      <gl-icon name="chevron-lg-right" class="gl-mr-2" :class="{ 'gl-rotate-90': showSection }" />
      <h3 class="gl-my-0! gl-font-lg">
        {{ $options.i18n.heading }}
      </h3>
    </header>
    <gl-collapse :visible="showSection">
      <div class="generic-report-container" data-testid="reports">
        <div
          v-for="[label, item] in detailsEntries"
          :key="label"
          class="generic-report-row"
          :data-testid="`report-row-${label}`"
        >
          <strong class="generic-report-column">{{ item.name || label }}</strong>
          <div class="generic-report-column" data-testid="reportContent">
            <report-item :item="item" :data-testid="`report-item-${label}`" />
          </div>
        </div>
      </div>
    </gl-collapse>
  </section>
</template>
