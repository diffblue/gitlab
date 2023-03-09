<script>
import { GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { slugifyWithUnderscore } from '~/lib/utils/text_utility';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import SubscriptionSyncButton from 'ee/admin/subscriptions/show/components/subscription_sync_button.vue';
import { copySubscriptionIdButtonText, detailsLabels, subscriptionTypes } from '../constants';

const placeholderHeightFactor = 32;
const placeholderWidth = 180;
const DEFAULT_TD_CLASSES = 'gl-border-none! gl-h-7 gl-line-height-normal! gl-p-0!';

export default {
  detailsLabels,
  i18n: {
    copySubscriptionIdButtonText,
  },
  fields: [
    {
      key: 'label',
      label: '',
      tdClass: `${DEFAULT_TD_CLASSES} gl-w-13`,
    },
    {
      key: 'value',
      formatter: (v, k, item) => item.value?.toString() || '-',
      label: '',
      tdClass: DEFAULT_TD_CLASSES,
    },
  ],
  name: 'SubscriptionDetailsTable',
  components: {
    ClipboardButton,
    GlSkeletonLoader,
    GlTableLite,
    SubscriptionSyncButton,
  },
  props: {
    details: {
      type: Array,
      required: true,
    },
    subscriptionType: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['didSyncFail']),
    hasContent() {
      return this.details.some(({ value }) => Boolean(value));
    },
    placeholderContainerHeight() {
      return this.details.length * placeholderHeightFactor;
    },
    placeholderContainerWidth() {
      return placeholderWidth;
    },
    placeHolderHeight() {
      return placeholderHeightFactor / 2;
    },
  },
  methods: {
    placeHolderPosition(index) {
      return (index - 1) * placeholderHeightFactor;
    },
    qaSelectorValue({ detail }) {
      return slugifyWithUnderscore(detail);
    },
    rowAttr({ detail }, type) {
      return {
        'data-testid': `${type}-${slugifyWithUnderscore(detail)}`,
      };
    },
    lastSyncFailed(item) {
      return item.detail === 'lastSync' && this.didSyncFail;
    },
    rowClass(item) {
      return this.lastSyncFailed(item) ? `gl-text-red-500` : 'gl-text-gray-800';
    },
    rowLabel({ detail }) {
      return this.$options.detailsLabels[detail];
    },
    shouldShowDetail(detail) {
      return (
        detail === 'lastSync' &&
        this.subscriptionType !== subscriptionTypes.OFFLINE_CLOUD &&
        this.subscriptionType !== subscriptionTypes.LEGACY_LICENSE
      );
    },
  },
};
</script>

<template>
  <gl-table-lite
    v-if="hasContent"
    :fields="$options.fields"
    :items="details"
    class="gl-m-0!"
    thead-class="gl-display-none"
    :tbody-tr-attr="rowAttr"
    :tbody-tr-class="rowClass"
  >
    <template #cell(label)="{ item }">
      <p class="gl-font-weight-bold" data-testid="details-label">{{ rowLabel(item) }}:</p>
    </template>

    <template #cell(value)="{ item, value }">
      <p
        class="gl-relative"
        data-testid="details-content"
        :data-qa-selector="qaSelectorValue(item)"
      >
        {{ value }}
        <clipboard-button
          v-if="item.detail === 'id'"
          :text="value"
          :title="$options.i18n.copySubscriptionIdButtonText"
          :aria-label="$options.i18n.copySubscriptionIdButtonText"
          category="tertiary"
          class="gl-absolute gl-mt-n2 gl-ml-2"
          size="small"
        />
        <subscription-sync-button v-if="shouldShowDetail(item.detail)" />
      </p>
    </template>
  </gl-table-lite>
  <div
    v-else
    :style="{ height: `${placeholderContainerHeight}px`, width: `${placeholderContainerWidth}px` }"
    class="gl-pt-2"
  >
    <gl-skeleton-loader :height="placeholderContainerHeight" :width="placeholderContainerWidth">
      <rect
        v-for="index in details.length"
        :key="index"
        :height="placeHolderHeight"
        :width="placeholderContainerWidth"
        :y="placeHolderPosition(index)"
        rx="8"
      />
    </gl-skeleton-loader>
  </div>
</template>
