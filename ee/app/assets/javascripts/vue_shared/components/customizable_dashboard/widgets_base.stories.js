import { s__ } from '~/locale';
import WidgetsBase from './widgets_base.vue';

export default {
  component: WidgetsBase,
  title: 'ee/vue_shared/components/widgets_base',
};

const Template = (args, { argTypes }) => ({
  components: { WidgetsBase },
  props: Object.keys(argTypes),
  template: '<widgets-base v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  component: 'CubeLineChart',
  title: s__('ProductAnalytics|Audience'),
  data: {},
  chartOptions: {},
  customizations: {},
};
