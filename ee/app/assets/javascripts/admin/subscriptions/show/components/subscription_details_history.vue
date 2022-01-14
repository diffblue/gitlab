<script>
import { GlTooltip, GlTooltipDirective, GlIcon, GlBadge, GlTableLite } from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  cloudLicenseText,
  detailsLabels,
  licenseFileText,
  subscriptionTable,
  subscriptionTypes,
} from '../constants';

const DEFAULT_BORDER_CLASSES = 'gl-border-b-1! gl-border-b-gray-100! gl-border-b-solid!';
const DEFAULT_TH_CLASSES = 'gl-bg-white! gl-border-t-0! gl-pb-5! gl-px-5! gl-text-gray-700!';
const DEFAULT_TD_CLASSES = 'gl-py-5!';
const tdAttr = (_, key) => ({ 'data-testid': `subscription-cell-${kebabCase(key)}` });
const tdClassBase = [DEFAULT_BORDER_CLASSES, DEFAULT_TD_CLASSES];
const tdClassHighlight = [...tdClassBase, 'gl-bg-blue-50!'];
const thClass = [DEFAULT_BORDER_CLASSES, DEFAULT_TH_CLASSES];

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
          thClass,
        },
        {
          key: 'plan',
          formatter: (v, k, item) => capitalizeFirstCharacter(item.plan),
          label: detailsLabels.plan,
          tdAttr,
          tdClass: this.cellClass,
          thClass,
        },
        {
          key: 'activatedAt',
          label: subscriptionTable.activatedAt,
          tdAttr,
          tdClass: this.cellClass,
          thClass,
        },
        {
          key: 'startsAt',
          label: subscriptionTable.startsAt,
          tdAttr,
          tdClass: this.cellClass,
          thClass,
        },
        {
          key: 'expiresAt',
          label: subscriptionTable.expiresOn,
          tdAttr,
          tdClass: this.cellClass,
          thClass,
        },
        {
          key: 'usersInLicenseCount',
          label: subscriptionTable.seats,
          tdAttr,
          tdClass: this.cellClass,
          thClass,
        },
        {
          key: 'type',
          formatter: (v, k, item) =>
            item.type === subscriptionTypes.LICENSE_FILE ? licenseFileText : cloudLicenseText,
          label: subscriptionTable.type,
          tdAttr,
          tdClass: this.cellClass,
          thClass,
        },
      ],
    };
  },
  methods: {
    cellClass(_, x, item) {
      return this.isCurrentSubscription(item) ? tdClassHighlight : tdClassBase;
    },
    isCurrentSubscription({ id }) {
      return id === this.currentSubscriptionId;
    },
    rowAttr(item) {
      return {
        'data-testid': this.isCurrentSubscription(item)
          ? 'subscription-current'
          : 'subscription-history-row',
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
