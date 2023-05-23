<script>
export default {
  name: 'AiGenieLoader',
};
</script>

<template>
  <div class="ai-genie-loader">
    <div
      class="ai-genie-chat-message gl-bg-gray-50 gl-display-inline-block gl-py-3 gl-px-4 gl-mb-4 gl-rounded-lg gl-rounded-bottom-left-none"
    >
      <div class="ai-genie-loader__dot ai-genie-loader__dot--1"></div>
      <div class="ai-genie-loader__dot ai-genie-loader__dot--2"></div>
      <div class="ai-genie-loader__dot ai-genie-loader__dot--3"></div>
      <span class="gl-sr-only">{{ __('Loading') }}</span>
    </div>
  </div>
</template>
