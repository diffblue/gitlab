<template>
  <div
    class="row gl-flex-grow-1 gl-flex-direction-column gl-flex-nowrap gl-lg-flex-direction-row gl-xl-flex-direction-row gl-lg-flex-wrap gl-xl-flex-wrap"
  >
    <div
      class="checkout-pane gl-px-3 gl-pt-5 gl-align-items-center gl-bg-gray-10 col-lg-7 gl-display-flex gl-flex-direction-column gl-flex-grow-1"
    >
      <slot name="checkout"></slot>
    </div>
    <div
      class="gl-pb-3 gl-px-3 gl-lg-px-7 col-lg-5 gl-display-flex gl-flex-direction-row gl-justify-content-center"
    >
      <slot name="order-summary"></slot>
    </div>
  </div>
</template>
