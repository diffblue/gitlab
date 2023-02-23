<template>
  <div>
    <slot name="alerts"></slot>
    <h2 class="gl-lg-mx-12 gl-mt-0 gl-mb-6">{{ s__('Checkout|Checkout') }}</h2>
    <div class="gl-lg-display-flex gl-flex-direction-row gl-flex-nowrap">
      <div class="gl-lg-w-40p gl-lg-ml-12 gl-lg-mr-10 gl-px-0">
        <slot name="checkout"></slot>
      </div>
      <div class="gl-lg-w-30p gl-lg-ml-10 gl-lg-mr-12 gl-px-0">
        <slot name="order-summary"></slot>
      </div>
    </div>
  </div>
</template>
