<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlIcon,
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
    GlAlert,
    GlBadge,
    GlButton,
    GlLoadingIcon,
    GlModal,
    GlIcon,
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
    label: s__('AI|Write a brief description and have AI fill in the details.'),
    actionCancel: { text: __('Cancel') },
    buttonTitle: s__('AI|Write a summary to fill out the selected issue template'),
    placeholder: s__(
      'AI|For example: Organizations should be able to forecast into the future by using value stream analytics charts. This feature would help them understand how their metrics are trending.',
    ),
    autocompleteButtonText: s__('AI|Autocomplete'),
    actionPrimary: __('Submit'),
    error: __('Failed to generate description'),
    experiment: __('Experiment'),
    modalTitle: s__('AI|Populate issue description'),
    modalWarning: s__('AI|The existing description will be replaced when you submit.'),
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
      icon="tanuki-ai"
      :title="$options.i18n.buttonTitle"
      @click="hideTooltip"
      >{{ $options.i18n.autocompleteButtonText }}</gl-button
    >
    <gl-modal
      v-model="visible"
      :action-cancel="$options.i18n.actionCancel"
      :action-primary="actionPrimary"
      :modal-id="$options.convertDescriptionModalId"
      size="sm"
      @hidden="clearError"
      @primary="submit"
    >
      <template #modal-title>
        <div class="gl-display-flex gl-align-items-center">
          <gl-icon name="tanuki-ai" class="gl-text-purple-600" />
          <span class="gl-mx-3">{{ $options.i18n.modalTitle }}</span>
          <gl-badge variant="neutral">{{ $options.i18n.experiment }}</gl-badge>
        </div>
      </template>
      <div v-if="loading" class="gl-display-flex gl--flex-center">
        <gl-loading-icon size="md" /><span class="gl-ml-3">{{ loadingText }}</span>
      </div>
      <div v-else>
        <label for="feature-flag-description" class="label-bold">
          {{ $options.i18n.label }}
        </label>
        <textarea
          ref="textarea"
          v-model="description"
          rows="5"
          :aria-label="$options.i18n.label"
          :placeholder="$options.i18n.placeholder"
          class="gl-w-full gl-p-3"
          @keydown.ctrl.enter="submit"
          @keydown.meta.enter="submit"
        ></textarea>
      </div>
      <div v-if="error" class="gl-text-red-500" data-testid="convert-description-modal-error">
        {{ error }}
      </div>
      <gl-alert variant="warning" :dismissible="false" class="mt-2">
        {{ $options.i18n.modalWarning }}
      </gl-alert>
    </gl-modal>
  </div>
</template>
