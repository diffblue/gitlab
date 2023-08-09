<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';

export default {
  components: {
    GlButton,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['settings']),
  },
  methods: {
    ...mapActions(['requestEditRule', 'requestDeleteRule']),
  },
};
</script>

<template>
  <div class="gl-py-4 gl-px-5">
    <gl-button @click="requestEditRule(rule)">
      <span>{{ __('Edit') }}</span>
    </gl-button>
    <gl-button
      class="gl-ml-2 btn btn-inverted"
      variant="danger"
      category="primary"
      icon="remove"
      :aria-label="__('Remove')"
      @click="requestDeleteRule(rule)"
    />
  </div>
</template>
