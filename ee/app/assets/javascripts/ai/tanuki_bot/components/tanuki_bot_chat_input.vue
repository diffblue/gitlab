<script>
import { GlFormTextarea, GlLink, GlSprintf, GlButton } from '@gitlab/ui';
import { mapState } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  name: 'TanukiBotChatInput',
  i18n: {
    askAQuestion: s__('TanukiBot|Ask a question about GitLab'),
    exampleQuestion: s__('TanukiBot|For example, %{linkStart}what is a fork?%{linkEnd}'),
    whatIsAForkQuestion: s__('TanukiBot|What is a fork?'),
    send: __('Send'),
  },
  components: {
    GlFormTextarea,
    GlLink,
    GlSprintf,
    GlButton,
  },
  data() {
    return {
      message: '',
    };
  },
  computed: {
    ...mapState(['loading']),
  },
  methods: {
    handleSubmit() {
      if (this.loading) {
        return;
      }

      this.$emit('submit', this.message);
      this.message = '';
    },
    handleWhatIsAForkClick() {
      if (this.loading) {
        return;
      }

      this.$emit('submit', this.$options.i18n.whatIsAForkQuestion);
    },
  },
};
</script>

<template>
  <div>
    <gl-form-textarea
      v-model="message"
      :placeholder="$options.i18n.askAQuestion"
      :no-resize="false"
      class="tanuki-bot-chat-input-field"
      autofocus
      @keydown.enter.prevent="handleSubmit"
    />
    <div class="gl-text-gray-500 gl-my-3">
      <gl-sprintf :message="$options.i18n.exampleQuestion">
        <template #link="{ content }">
          <gl-link
            class="gl-text-gray-500 gl-text-decoration-underline"
            @click="handleWhatIsAForkClick"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </div>
    <div class="gl-display-flex gl-justify-content-end">
      <gl-button
        icon="paper-airplane"
        variant="confirm"
        :disabled="loading"
        @click="handleSubmit"
        >{{ $options.i18n.send }}</gl-button
      >
    </div>
  </div>
</template>
