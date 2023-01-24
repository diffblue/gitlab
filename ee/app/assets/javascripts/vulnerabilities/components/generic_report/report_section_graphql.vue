<script>
import { GlCollapse, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ReportItem, { GRAPHQL_TYPENAMES } from './report_item_graphql.vue';

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
    reportItems: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      showSection: true,
    };
  },
  computed: {
    itemsToRender() {
      return this.reportItems.filter(({ type }) => GRAPHQL_TYPENAMES.includes(type));
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
  <section v-if="itemsToRender.length > 0">
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
          v-for="(item, index) in itemsToRender"
          :key="index"
          class="generic-report-row"
          :data-testid="`report-row-${item.type}`"
        >
          <strong class="generic-report-column">{{ item.name || item.type }}</strong>
          <div class="generic-report-column" data-testid="reportContent">
            <report-item :item="item" :data-testid="`report-item-${item.type}`" />
          </div>
        </div>
      </div>
    </gl-collapse>
  </section>
</template>
