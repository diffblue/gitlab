<script>
import {
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import { getDraft, updateDraft, clearDraft } from '~/lib/utils/autosave';
import { fetchPolicies } from '~/lib/graphql';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';

const MAX_AI_WAIT_TIME = 20000;

export default {
  components: {
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    resourceId: {
      type: String,
      required: true,
    },
    userId: {
      type: String,
      required: true,
    },
  },
  data() {
    const autosaveKey = `convert_description_prompts/${this.resourceId}`;
    return {
      loading: false,
      loadingText: '',
      visible: false,
      error: '',
      autosaveKey,
      description: getDraft(autosaveKey),
    };
  },
  apollo: {
    $subscribe: {
      aiCompletionResponse: {
        query: aiResponseSubscription,
        skip() {
          return !this.loading;
        },
        fetchPolicy: fetchPolicies.NO_CACHE,
        variables() {
          return {
            resourceId: this.resourceId,
            userId: this.userId,
          };
        },
        async result({ data }) {
          const { errors = [], responseBody } = data.aiCompletionResponse || {};

          if (errors.length > 0) {
            this.handleError(errors[0].message);
          }

          if (!responseBody) {
            return;
          }

          clearTimeout(this.timeout);

          const content = `${responseBody}\n\n***\n_Description was generated using AI_`;

          this.$emit('contentGenerated', content);
          this.visible = false;
          this.loading = false;

          clearDraft(this.autosaveKey);
        },
      },
    },
  },
  i18n: {
    title: s__('AI|Describe the issue'),
    actionCancel: { text: __('Cancel') },
    buttonTitle: s__('AI|Write a summary to fill out the selected issue template'),
    placeholder: s__(
      'AI|For example: It should be possible to forecast into the future using our value stream analytics charts. This would allow organizations to better understand how they are trending on important metrics.',
    ),
    actionPrimary: s__('AI|Autocomplete'),
    error: __('Failed to generate description'),
    experiment: __('Experiment'),
  },
  computed: {
    actionPrimary() {
      return {
        attributes: {
          variant: 'confirm',
          disabled: this.loading || !this.description,
        },
        text: this.$options.i18n.actionPrimary,
      };
    },
  },
  watch: {
    description(val) {
      updateDraft(this.autosaveKey, val);
    },
  },
  methods: {
    hideTooltip() {
      this.$root.$emit(BV_HIDE_TOOLTIP);
    },
    submit(bvModalEvent) {
      // don't close modal on submit
      bvModalEvent.preventDefault();

      clearTimeout(this.timeout);
      this.clearError();

      this.loadingText = __('Loading');

      this.timeout = setTimeout(() => {
        this.handleError(this.$options.i18n.error);
      }, MAX_AI_WAIT_TIME);

      this.loading = true;
      this.$apollo
        .mutate({
          mutation: aiActionMutation,
          variables: {
            input: {
              generateDescription: {
                resourceId: this.resourceId,
                content: this.description,
                descriptionTemplateName: document
                  .querySelector('.js-issuable-selector')
                  ?.textContent?.trim(),
              },
            },
          },
        })
        .then(({ data: { aiAction } }) => {
          if (aiAction.errors.length > 0) {
            this.handleError(new Error(aiAction.errors));
          }
        })
        .catch(this.handleError);
    },
    handleError(error) {
      this.loading = false;
      this.error = error;
      clearTimeout(this.timeout);
    },
    clearError() {
      this.error = '';
    },
  },

  convertDescriptionModalId: 'convert-description-modal-id',
};
</script>

<template>
  <div>
    <gl-button
      v-if="resourceId"
      v-gl-modal="$options.convertDescriptionModalId"
      v-gl-tooltip
      :title="$options.i18n.buttonTitle"
      @click="hideTooltip"
      >{{ $options.i18n.actionPrimary }}</gl-button
    >
    <gl-badge variant="info">{{ $options.i18n.experiment }}</gl-badge>
    <gl-modal
      v-model="visible"
      :action-cancel="$options.i18n.actionCancel"
      :action-primary="actionPrimary"
      :modal-id="$options.convertDescriptionModalId"
      size="sm"
      :title="$options.i18n.title"
      @hidden="clearError"
      @primary="submit"
    >
      <div v-if="loading" class="gl-display-flex gl--flex-center">
        <gl-loading-icon size="md" /><span class="gl-ml-3">{{ loadingText }}</span>
      </div>
      <textarea
        v-else
        ref="textarea"
        v-model="description"
        rows="5"
        :placeholder="$options.i18n.placeholder"
        class="gl-w-full gl-p-3"
        @keydown.ctrl.enter="submit"
        @keydown.meta.enter="submit"
      ></textarea>
      <div v-if="error" class="gl-text-red-500" data-testid="convert-description-modal-error">
        {{ error }}
      </div>
    </gl-modal>
  </div>
</template>
