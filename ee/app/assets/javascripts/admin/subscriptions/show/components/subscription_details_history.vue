<script>
import { GlTooltip, GlTooltipDirective, GlIcon, GlBadge, GlTableLite } from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { detailsLabels, subscriptionTable } from '../constants';
import { getLicenseTypeLabel } from '../utils';

const tdAttr = (_, key) => ({ 'data-testid': `subscription-cell-${kebabCase(key)}` });
const tdClassHighlight = 'gl-bg-blue-50!';

export default {
  i18n: {
    subscriptionHistoryTitle: subscriptionTable.title,
    detailsLabels,
  },
  name: 'SubscriptionDetailsHistory',
  components: {
    GlBadge,
    GlIcon,
    GlTooltip,
    GlTableLite,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    currentSubscriptionId: {
      type: String,
      required: false,
      default: null,
    },
    subscriptionList: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      fields: [
        {
          key: 'name',
          label: detailsLabels.name,
          tdAttr,
          tdClass: this.cellClass,
        },
        {
          key: 'plan',
          formatter: (v, k, item) => capitalizeFirstCharacter(item.plan),
          label: detailsLabels.plan,
          tdAttr,
          tdClass: this.cellClass,
        },
        {
          key: 'activatedAt',
          formatter: (v, k, { activatedAt }) => {
            if (!activatedAt) {
              return '-';
            }

            return activatedAt;
          },
          label: subscriptionTable.activatedAt,
          tdAttr,
          tdClass: this.cellClass,
        },
        {
          key: 'startsAt',
          label: subscriptionTable.startsAt,
          tdAttr,
          tdClass: this.cellClass,
        },
        {
          key: 'expiresAt',
          label: subscriptionTable.expiresOn,
          tdAttr,
          tdClass: this.cellClass,
        },
        {
          key: 'usersInLicenseCount',
          label: subscriptionTable.seats,
          tdAttr,
          tdClass: this.cellClass,
        },
        {
          key: 'type',
          formatter: (v, k, item) => getLicenseTypeLabel(item.type),
          label: subscriptionTable.type,
          tdAttr,
          tdClass: this.cellClass,
        },
      ],
    };
  },
  methods: {
    cellClass(_, x, item) {
      return this.isCurrentSubscription(item) ? tdClassHighlight : '';
    },
    isCurrentSubscription({ id }) {
      return id === this.currentSubscriptionId;
    },
    rowAttr() {
      return {
        'data-testid': 'subscription-history-row',
      };
    },
    rowClass(item) {
      return this.isCurrentSubscription(item) ? 'gl-font-weight-bold gl-text-blue-500' : '';
    },
  },
};
</script>

<template>
  <section>
    <header>
      <h2 class="gl-mb-6 gl-mt-0">{{ $options.i18n.subscriptionHistoryTitle }}</h2>
    </header>
    <gl-table-lite
      :details-td-class="$options.tdClass"
      :fields="fields"
      :items="subscriptionList"
      :tbody-tr-attr="rowAttr"
      :tbody-tr-class="rowClass"
      responsive
      stacked="sm"
      data-qa-selector="subscription_history"
    >
      <template #cell(name)="{ item }">
        <span>
          <gl-icon :id="`tooltip-name-${item.id}`" v-gl-tooltip name="information-o" tabindex="0" />
          <gl-tooltip :target="`tooltip-name-${item.id}`">
            {{ item.email }}<br />({{ item.company }})
          </gl-tooltip>
          {{ item.name }}
          <span class="sr-only" data-testid="subscription-history-sr-only">
            {{ $options.i18n.detailsLabels.email }}: {{ item.email }}<br />({{
              $options.i18n.detailsLabels.company
            }}: {{ item.company }})
          </span>
        </span>
      </template>
      <template #cell(type)="{ value }">
        <gl-badge size="md" variant="info">{{ value }}</gl-badge>
      </template>
    </gl-table-lite>
  </section>
</template>
