<template>
  <article>
    <slot name="alert"></slot>
    <header
      class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-display-flex gl-justify-content-space-between"
    >
      <div>
        <h4 class="gl-mt-0">
          <slot name="heading"></slot>
        </h4>
        <p>
          <slot name="description"></slot>
        </p>
      </div>
      <div>
        <slot name="actions"></slot>
      </div>
    </header>
    <slot></slot>
  </article>
</template>
