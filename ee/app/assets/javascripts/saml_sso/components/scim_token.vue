<script>
import { GlSprintf, GlButton, GlLoadingIcon, GlModal } from '@gitlab/ui';

import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import InputCopyToggleVisibility from '~/vue_shared/components/form/input_copy_toggle_visibility.vue';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlSprintf,
    InputCopyToggleVisibility,
    GlButton,
    GlLoadingIcon,
    GlModal,
  },
  i18n: {
    copyToken: s__('GroupSaml|Copy SCIM token'),
    copyEndpointUrl: s__('GroupSaml|Copy SCIM API endpoint URL'),
    tokenLabel: s__('GroupSaml|Your SCIM token'),
    endpointUrlLabel: s__('GroupSaml|SCIM API endpoint URL'),
    generateTokenButtonText: s__('GroupSAML|Generate a SCIM token'),
    tokenHasNotBeenGeneratedMessage: s__(
      'GroupSAML|Generate a SCIM token to set up your System for Cross-Domain Identity Management.',
    ),
    tokenNeedsToBeResetDescription: s__(
      'GroupSAML|The SCIM token is now hidden. To see the value of the token again, you need to %{linkStart}reset it%{linkEnd}.',
    ),
    tokenHasBeenGeneratedOrResetDescription: s__(
      "GroupSAML|Make sure you save this token — you won't be able to access it again.",
    ),
    generateTokenErrorMessage: s__(
      'GroupSAML|An error occurred generating your SCIM token. Please try again.',
    ),
    resetTokenErrorMessage: s__(
      'GroupSAML|An error occurred resetting your SCIM token. Please try again.',
    ),
    modal: {
      title: __('Are you sure?'),
      body: s__(
        'GroupSAML|Are you sure you want to reset the SCIM token? SCIM provisioning will stop working until the new token is updated.',
      ),
    },
  },
  modal: {
    id: 'reset-scim-token-modal',
    actionPrimary: {
      text: s__('GroupSAML|Reset SCIM token'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  tokenInputId: 'scim_token',
  endpointUrlInputId: 'scim_token_endpoint_url',
  inject: ['initialEndpointUrl', 'generateTokenPath'],
  data() {
    return {
      loading: false,
      token: '',
      endpointUrl: this.initialEndpointUrl,
      modalVisible: false,
    };
  },
  computed: {
    tokenHasNotBeenGenerated() {
      return !this.endpointUrl && this.token === '';
    },
    tokenNeedsToBeReset() {
      return this.endpointUrl && this.token === '';
    },
    tokenInputValue() {
      return this.tokenNeedsToBeReset ? '*'.repeat(20) : this.token;
    },
    tokenFormInputGroupProps() {
      return { id: this.$options.tokenInputId, class: 'gl-form-input-xl' };
    },
    tokenEndpointUrlFormInputGroupProps() {
      return { id: this.$options.endpointUrlInputId, class: 'gl-form-input-xl' };
    },
    contentContainerClasses() {
      return { 'gl-visibility-hidden': this.loading };
    },
  },
  methods: {
    async callApi(errorMessage) {
      this.loading = true;

      try {
        const {
          data: { scim_api_url: endpointUrl, scim_token: token },
        } = await axios.post(this.generateTokenPath);

        this.token = token;
        this.endpointUrl = endpointUrl;
      } catch (error) {
        createAlert({
          message: errorMessage,
          captureError: true,
          error,
        });
      } finally {
        this.loading = false;
      }
    },
    handleGenerateTokenButtonClick() {
      this.callApi(this.$options.i18n.generateTokenErrorMessage);
    },
    handleModalPrimary() {
      this.callApi(this.$options.i18n.resetTokenErrorMessage);
    },
    handleResetButtonClick() {
      this.modalVisible = true;
    },
  },
};
</script>

<template>
  <div class="gl-mt-5 gl-relative">
    <gl-modal
      v-model="modalVisible"
      :modal-id="$options.modal.id"
      :title="$options.i18n.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="sm"
      @primary="handleModalPrimary"
    >
      {{ $options.i18n.modal.body }}
    </gl-modal>
    <div
      v-if="loading"
      class="gl-absolute gl-top-5 gl-left-0 gl-right-0 gl-display-flex gl-justify-content-center"
    >
      <gl-loading-icon size="lg" />
    </div>
    <div
      v-if="tokenHasNotBeenGenerated"
      :class="contentContainerClasses"
      data-testid="content-container"
    >
      <p>
        {{ $options.i18n.tokenHasNotBeenGeneratedMessage }}
      </p>
      <gl-button @click="handleGenerateTokenButtonClick">{{
        $options.i18n.generateTokenButtonText
      }}</gl-button>
    </div>
    <div v-else :class="contentContainerClasses" data-testid="content-container">
      <input-copy-toggle-visibility
        :label="$options.i18n.tokenLabel"
        :label-for="$options.tokenInputId"
        :form-input-group-props="tokenFormInputGroupProps"
        :value="tokenInputValue"
        :copy-button-title="$options.i18n.copyToken"
        :show-toggle-visibility-button="!tokenNeedsToBeReset"
        :show-copy-button="!tokenNeedsToBeReset"
      >
        <template #description>
          <gl-sprintf
            v-if="tokenNeedsToBeReset"
            :message="$options.i18n.tokenNeedsToBeResetDescription"
          >
            <template #link="{ content }">
              <gl-button variant="link" @click="handleResetButtonClick">{{ content }}</gl-button>
            </template>
          </gl-sprintf>
          <template v-else>
            {{ $options.i18n.tokenHasBeenGeneratedOrResetDescription }}
          </template>
        </template>
      </input-copy-toggle-visibility>
      <input-copy-toggle-visibility
        :label="$options.i18n.endpointUrlLabel"
        :label-for="$options.endpointUrlInputId"
        :form-input-group-props="tokenEndpointUrlFormInputGroupProps"
        :value="endpointUrl"
        :copy-button-title="$options.i18n.copyEndpointUrl"
        :show-toggle-visibility-button="false"
      />
    </div>
  </div>
</template>
