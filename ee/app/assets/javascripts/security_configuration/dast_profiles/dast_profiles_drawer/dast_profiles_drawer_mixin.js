import { SCANNER_TYPE } from 'ee/on_demand_scans/constants';

export default () => ({
  props: {
    profile: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    profileType: {
      type: String,
      required: false,
      default: SCANNER_TYPE,
    },
  },
});
