<template>
  <article>
    <slot name="alert"></slot>
    <header class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h4>
        <slot name="heading"></slot>
      </h4>
      <p>
        <slot name="description"></slot>
      </p>
    </header>
    <slot></slot>
  </article>
</template>
