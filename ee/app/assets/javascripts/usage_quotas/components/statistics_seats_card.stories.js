import { GlCard } from '@gitlab/ui';
import StatisticsSeatsCard from './statistics_seats_card.vue';

export default {
  component: StatisticsSeatsCard,
  title: 'ee/usage_quotas/statistics_seats_card',
};

const Template = (_, { argTypes }) => ({
  components: { StatisticsSeatsCard, GlCard },
  props: Object.keys(argTypes),
  template: `<gl-card class="gl-w-half">
      <statistics-seats-card v-bind="$props">
      </statistics-seats-card>
     </gl-card>`,
});
export const Default = Template.bind({});

Default.args = {
  seatsUsed: 160,
  seatsOwed: 10,
  purchaseButtonLink: 'purchase.com/test',
};
