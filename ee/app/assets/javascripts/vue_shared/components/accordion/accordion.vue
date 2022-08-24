<script>
import { uniqueId } from 'lodash';

export default {
  props: {
    listClasses: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  created() {
    this.uniqueId = uniqueId('accordion-');
  },
};
</script>
<template>
  <div>
    <ul class="list-group list-group-flush py-2" :class="listClasses">
      <slot :accordion-id="uniqueId"></slot>
    </ul>
  </div>
</template>
