<script>
import getProductAnalyticsState from '../../graphql/queries/get_product_analytics_state.query.graphql';
import {
  SHORT_POLLING_INTERVAL,
  LONG_POLLING_INTERVAL,
  STATE_CREATE_INSTANCE,
  STATE_LOADING_INSTANCE,
  STATE_WAITING_FOR_EVENTS,
  STATE_COMPLETE,
} from '../constants';

export default {
  name: 'ProductAnalyticsOnboardingState',
  inject: {
    projectFullPath: {
      type: String,
    },
  },
  model: {
    prop: 'state',
    event: 'change',
  },
  props: {
    state: {
      type: String,
      required: false,
      default: '',
    },
    pollState: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      hasError: false,
    };
  },
  computed: {
    pollingEnabled() {
      // Automatically enable polling when waiting for events or loading
      return (
        this.state === STATE_WAITING_FOR_EVENTS ||
        this.state === STATE_LOADING_INSTANCE ||
        this.pollState
      );
    },
    creatingInstance() {
      return this.state === STATE_CREATE_INSTANCE || this.state === STATE_LOADING_INSTANCE;
    },
  },
  apollo: {
    state: {
      query: getProductAnalyticsState,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      pollInterval() {
        if (!this.pollingEnabled) {
          return 0;
        }

        // Use faster polling when creating the instance because the action is quicker
        return this.creatingInstance ? SHORT_POLLING_INTERVAL : LONG_POLLING_INTERVAL;
      },
      skip() {
        return this.hasError;
      },
      update(data) {
        const state = data?.project?.productAnalyticsState;

        this.onStateChange(state);

        return state;
      },
      error(err) {
        this.onError(err);
      },
    },
  },
  methods: {
    onStateChange(state) {
      this.$emit('change', state);

      if (state === STATE_COMPLETE) {
        this.$emit('complete');
      }
    },
    onError(err) {
      this.hasError = true;
      this.$emit('error', err);
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
