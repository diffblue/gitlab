<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import SubscriptionTable from './subscription_table.vue';

export default {
  name: 'SubscriptionApp',
  components: {
    SubscriptionTable,
  },
  inject: {
    namespaceId: {
      default: null,
    },
  },
  created() {
    this.setNamespaceId(this.namespaceId);
  },
  methods: {
    ...mapActions(['setNamespaceId']),
  },
};
</script>

<template>
  <subscription-table />
</template>
