import { s__ } from '~/locale';
import PanelsBase from './panels_base.vue';

export default {
  component: PanelsBase,
  title: 'ee/vue_shared/components/panels_base',
};

const Template = (args, { argTypes }) => ({
  components: { PanelsBase },
  props: Object.keys(argTypes),
  template: '<panels-base v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  component: 'CubeLineChart',
  title: s__('ProductAnalytics|Audience'),
  data: {},
  chartOptions: {},
  customizations: {},
};
