<script>
import createFlash from '~/flash';
import { __ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Mediator from '../../sidebar_mediator';
import weightComponent from './weight.vue';

export default {
  components: {
    weight: weightComponent,
  },
  data() {
    return {
      // Defining `mediator` here as a data prop
      // makes it reactive for any internal updates
      // which wouldn't happen otherwise.
      mediator: new Mediator(),
    };
  },
  created() {
    eventHub.$on('updateWeight', this.onUpdateWeight);
  },

  beforeDestroy() {
    eventHub.$off('updateWeight', this.onUpdateWeight);
  },

  methods: {
    onUpdateWeight({ value: newWeight }) {
      this.mediator.updateWeight(newWeight).catch(() => {
        createFlash({
          message: __('Error occurred while updating the issue weight'),
        });
      });
    },
  },
};
</script>

<template>
  <weight
    :fetching="mediator.store.isFetching.weight"
    :loading="mediator.store.isLoading.weight"
    :weight="mediator.store.weight"
    :weight-none-value="mediator.store.weightNoneValue"
    :editable="mediator.store.editable"
  />
</template>
