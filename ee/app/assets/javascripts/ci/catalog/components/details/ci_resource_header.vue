<script>
export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    rootNamespace: {
      type: Object,
      required: true,
    },
  },
  computed: {
    fullPath() {
      return `${this.rootNamespace.fullPath}/${this.rootNamespace.name}`;
    },
  },
};
</script>
<template>
  <div class="gl-border-b gl-pb-3">
    <div class="gl-display-flex">
      <img />
      <div>
        <div>
          {{ fullPath }}
        </div>
        <div>{{ name }}</div>
      </div>
    </div>
    <p>
      {{ description }}
    </p>
  </div>
</template>
