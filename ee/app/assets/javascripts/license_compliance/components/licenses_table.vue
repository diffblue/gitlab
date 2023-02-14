<script>
import { s__ } from '~/locale';
import LicensesTableRow from './licenses_table_row.vue';

export default {
  name: 'LicensesTable',
  components: {
    LicensesTableRow,
  },
  props: {
    licenses: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      tableHeaders: [
        { className: 'section-30', label: s__('Licenses|Name') },
        { className: 'section-70', label: s__('Licenses|Component') },
      ],
    };
  },
};
</script>

<template>
  <div>
    <div class="gl-responsive-table-row table-row-header text-2 gl-bg-gray-50 px-2" role="row">
      <div
        v-for="header in tableHeaders"
        :key="header.label"
        class="table-section"
        :class="header.className"
        role="rowheader"
      >
        {{ header.label }}
      </div>
    </div>

    <licenses-table-row
      v-for="license in licenses"
      :key="license.key"
      :license="license"
      :is-loading="isLoading"
    />
  </div>
</template>
