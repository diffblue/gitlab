<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { TABLE_COLUMNS } from '../constants';

export default {
  columns: TABLE_COLUMNS,
  components: {
    GlTable,
    GlLink,
  },
  props: {
    contributions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      sortBy: TABLE_COLUMNS[0].key,
      sortDesc: false,
    };
  },
};
</script>

<template>
  <div>
    <h3>{{ s__('ContributionAnalytics|Contributions per group member') }}</h3>
    <gl-table
      :items="contributions"
      :fields="$options.columns"
      :sort-by.sync="sortBy"
      :sort-desc.sync="sortDesc"
      stacked="lg"
    >
      <template
        #cell(user)="{
          item: {
            user: { name, webUrl },
          },
        }"
      >
        <gl-link :href="webUrl">
          <b>{{ name }}</b>
        </gl-link>
      </template>
    </gl-table>
  </div>
</template>
