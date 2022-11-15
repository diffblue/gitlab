import { GlCard } from '@gitlab/ui';
import StatisticsCard from './statistics_card.vue';

export default {
  component: StatisticsCard,
  title: 'usage_quotas/statistics_card',
};

const Template = (_, { argTypes }) => ({
  components: { StatisticsCard, GlCard },
  props: Object.keys(argTypes),
  template: `<gl-card class="gl-w-half">
      <statistics-card v-bind="$props">
      </statistics-card>
     </gl-card>`,
});
export const Default = Template.bind({});

Default.args = {
  usageValue: '1,400',
  totalValue: '1,500',
  description: 'Additional minutes used',
  helpLink: 'dummy.com/link',
  helpLabel: 'Help link label, used for aria-label',
  percentage: 84,
};

export const WithUnits = (_, { argTypes }) => ({
  components: { StatisticsCard, GlCard },
  props: Object.keys(argTypes),
  template: `<gl-card class="gl-w-half">
      <statistics-card v-bind="$props">
      </statistics-card>
     </gl-card>`,
});

WithUnits.args = {
  usageValue: '250.0',
  usageUnit: 'MiB',
  totalValue: '15.0',
  totalUnit: 'GiB',
  description: 'Storage used',
  helpLink: 'dummy.com/link',
  helpLabel: 'Help link label, used for aria-label',
  percentage: 4,
  purchaseButtonLink: 'purchase.com/test',
  purchaseButtonText: 'Purchase storage',
};
