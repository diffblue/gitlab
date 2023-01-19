<script>
import { GlTableLite, GlBadge, GlLink } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { formatDate } from '~/lib/utils/datetime_utility';
import { DETAILS_FIELDS } from '../constants';
import SubscriptionSeatDetailsLoader from './subscription_seat_details_loader.vue';

export default {
  name: 'SubscriptionSeatDetails',
  components: {
    GlBadge,
    GlTableLite,
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
    ...mapState({
      userDetailsEntry(state) {
        return state.userDetails[this.seatMemberId];
      },
    }),
    items() {
      return this.userDetailsEntry.items;
    },
    isLoaderShown() {
      return this.userDetailsEntry.isLoading || this.userDetailsEntry.hasError;
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
  <div v-if="isLoaderShown">
    <subscription-seat-details-loader />
  </div>
  <gl-table-lite
    v-else
    :fields="$options.fields"
    :items="items"
    data-testid="seat-usage-details"
    borderless
    class="gl-mb-0!"
  >
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
  </gl-table-lite>
</template>
