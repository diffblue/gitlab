import StatusBadge, { VARIANTS } from './status_badge.vue';

export default {
  component: StatusBadge,
  title: 'ee/vue_shared/security_reports/status_badge',
  argTypes: {
    state: {
      control: 'select',
      options: Object.keys(VARIANTS),
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { StatusBadge },
  props: Object.keys(argTypes),
  template: '<status-badge v-bind="$props" />',
});

export const Default = Template.bind({});

Default.args = {
  state: Object.keys(VARIANTS)[0],
};
