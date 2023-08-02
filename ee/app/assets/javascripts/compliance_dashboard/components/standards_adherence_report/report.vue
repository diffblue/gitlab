<script>
import ComplianceStandardsAdherenceTable from './standards_adherence_table.vue';

export default {
  name: 'ComplianceStandardsAdherenceReport',
  components: {
    ComplianceStandardsAdherenceTable,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <compliance-standards-adherence-table :group-path="groupPath" />
</template>
