<script>
export default {
  name: 'DastProfileSelectorEmptyState',
};
</script>

<template>
  <div>
    <div
      class="gl-bg-gray-10 gl-display-flex gl-flex-direction-column gl-text-center gl-align-items-center gl-p-6 gl-rounded-small gl-mb-5"
    >
      <h5 class="gl-h5 gl-text-gray-500 gl-mt-0 gl-mb-2">
        <slot name="header"></slot>
      </h5>
      <span class="gl-text-gray-500">
        <slot name="content"></slot>
      </span>
    </div>
  </div>
</template>
