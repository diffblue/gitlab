<script>
import { numberToHumanSize } from '~/lib/utils/number_utils';

export default {
  name: 'NumberToHumanSize',
  props: {
    value: {
      type: Number,
      required: true,
    },
    fractionDigits: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  computed: {
    formattedValue() {
      return numberToHumanSize(this.value, this.fractionDigits);
    },
  },
};
</script>
<template>
  <span>{{ formattedValue }}</span>
</template>
