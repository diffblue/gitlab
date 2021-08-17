<script>
import { GlTable, GlBadge, GlLink } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';
import { formatDate } from '~/lib/utils/datetime_utility';
import { DETAILS_FIELDS } from '../constants';
import SubscriptionSeatDetailsLoader from './subscription_seat_details_loader.vue';

export default {
  name: 'SubscriptionSeatDetails',
  components: {
    GlBadge,
    GlTable,
    GlLink,
    SubscriptionSeatDetailsLoader,
  },
  props: {
    seatMemberId: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['membershipsById']),
    state() {
      return this.membershipsById(this.seatMemberId);
    },
    items() {
      return this.state.items;
    },
    isLoading() {
      return this.state.isLoading;
    },
  },
  created() {
    this.fetchBillableMemberDetails(this.seatMemberId);
  },
  methods: {
    ...mapActions(['fetchBillableMemberDetails']),
    formatDate,
  },
  fields: DETAILS_FIELDS,
};
</script>

<template>
  <div v-if="isLoading">
    <subscription-seat-details-loader />
  </div>
  <gl-table v-else :fields="$options.fields" :items="items" data-testid="seat-usage-details">
    <template #cell(source_full_name)="{ item }">
      <gl-link :href="item.source_members_url" target="_blank">{{ item.source_full_name }}</gl-link>
    </template>
    <template #cell(created_at)="{ item }">
      <span>{{ formatDate(item.created_at, 'yyyy-mm-dd') }}</span>
    </template>
    <template #cell(expires_at)="{ item }">
      <span>{{ item.expires_at ? formatDate(item.expires_at, 'yyyy-mm-dd') : __('Never') }}</span>
    </template>
    <template #cell(role)="{ item }">
      <gl-badge>{{ item.access_level.string_value }}</gl-badge>
    </template>
  </gl-table>
</template>
