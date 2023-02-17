<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
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
  i18n: {
    header: s__('ContributionAnalytics|Contributions per group member'),
  },
};
</script>

<template>
  <div>
    <h3>{{ $options.i18n.header }}</h3>
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
        <gl-link :href="webUrl" class="gl-font-weight-bold">{{ name }}</gl-link>
      </template>
    </gl-table>
  </div>
</template>
