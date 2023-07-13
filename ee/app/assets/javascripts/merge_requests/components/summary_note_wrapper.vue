<template>
  <article class="gl-rounded-base gl-border gl-mb-4">
    <header class="gl-display-flex gl-justify-content-space-between gl-p-4">
      <slot name="title"></slot>
      <slot name="created"></slot>
    </header>
    <div class="gl-px-4 gl-mb-4"><slot name="content"></slot></div>
    <footer class="gl--flex-center gl-border-t gl-px-4 gl-py-3">
      <slot name="feedback"></slot>
      <div class="gl-ml-auto"><slot name="feedback-link"></slot></div>
    </footer>
  </article>
</template>
