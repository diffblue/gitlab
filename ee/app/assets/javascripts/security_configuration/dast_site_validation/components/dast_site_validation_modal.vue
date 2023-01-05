<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlFormRadioGroup,
  GlInputGroupText,
  GlModal,
  GlSkeletonLoader,
  GlTruncate,
  GlLink,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { helpPagePath } from '~/helpers/help_page_helper';
import download from '~/lib/utils/downloader';
import { cleanLeadingSeparator, joinPaths, stripPathTail } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import {
  DAST_SITE_VALIDATION_MODAL_ID,
  DAST_SITE_VALIDATION_HTTP_HEADER_KEY,
  DAST_SITE_VALIDATION_METHOD_HTTP_HEADER,
  DAST_SITE_VALIDATION_METHOD_TEXT_FILE,
  DAST_SITE_VALIDATION_METHOD_META_TAG,
  DAST_SITE_VALIDATION_METHODS,
} from '../constants';
import dastSiteTokenCreateMutation from '../graphql/dast_site_token_create.mutation.graphql';
import dastSiteValidationCreateMutation from '../graphql/dast_site_validation_create.mutation.graphql';

export default {
  name: 'DastSiteValidationModal',
  DAST_SITE_VALIDATION_MODAL_ID,
  components: {
    GlAlert,
    ModalCopyButton,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlFormRadioGroup,
    GlInputGroupText,
    GlModal,
    GlSkeletonLoader,
    GlTruncate,
    GlLink,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    targetUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isCreatingToken: false,
      hasErrors: false,
      token: null,
      tokenId: null,
      validationMethod: DAST_SITE_VALIDATION_METHOD_TEXT_FILE,
      validationPath: '',
      helpUrl: helpPagePath('user/application_security/dast/index', {
        anchor: 'site-profile-validation',
      }),
    };
  },
  computed: {
    modalProps() {
      return {
        id: DAST_SITE_VALIDATION_MODAL_ID,
        title: s__('DastSiteValidation|Validate site'),
        primaryProps: {
          text: s__('DastSiteValidation|Validate'),
          attributes: {
            disabled: this.hasErrors,
            variant: 'confirm',
            category: 'primary',
            'data-testid': 'validate-dast-site-button',
          },
        },
        cancelProps: {
          text: __('Cancel'),
        },
      };
    },
    validationMethodOptions() {
      return Object.values(DAST_SITE_VALIDATION_METHODS);
    },
    urlObject() {
      try {
        return new URL(this.targetUrl);
      } catch {
        return {};
      }
    },
    origin() {
      return this.urlObject.origin ? `${this.urlObject.origin}/` : '';
    },
    path() {
      return cleanLeadingSeparator(this.urlObject.pathname || '');
    },
    isTextFileValidation() {
      return this.validationMethod === DAST_SITE_VALIDATION_METHOD_TEXT_FILE;
    },
    isHttpHeaderValidation() {
      return this.validationMethod === DAST_SITE_VALIDATION_METHOD_HTTP_HEADER;
    },
    isMetaTagValidation() {
      return this.validationMethod === DAST_SITE_VALIDATION_METHOD_META_TAG;
    },
    textFileName() {
      return `GitLab-DAST-Site-Validation-${this.token}.txt`;
    },
    locationStepLabel() {
      return DAST_SITE_VALIDATION_METHODS[this.validationMethod].i18n.locationStepLabel;
    },
    httpHeader() {
      return `${DAST_SITE_VALIDATION_HTTP_HEADER_KEY}: ${this.token}`;
    },
    metaTag() {
      return `<meta name="gitlab-dast-validation" content="${this.token}">`;
    },
  },
  watch: {
    targetUrl: {
      immediate: true,
      handler: 'createValidationToken',
    },
  },
  created() {
    this.unsubscribe = this.$watch(
      () => [this.token, this.validationMethod],
      this.updateValidationPath,
      {
        immediate: true,
      },
    );
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    updateValidationPath() {
      this.validationPath = this.isTextFileValidation
        ? this.getTextFileValidationPath()
        : this.path;
    },
    getTextFileValidationPath() {
      return joinPaths(stripPathTail(this.path), this.textFileName);
    },
    onValidationPathInput() {
      this.unsubscribe();
    },
    downloadTextFile() {
      download({ fileName: this.textFileName, fileData: btoa(this.token) });
    },
    async createValidationToken() {
      this.isCreatingToken = true;
      this.hasErrors = false;
      try {
        const {
          data: {
            dastSiteTokenCreate: { errors, id, token },
          },
        } = await this.$apollo.mutate({
          mutation: dastSiteTokenCreateMutation,
          variables: {
            fullPath: this.fullPath,
            targetUrl: this.targetUrl,
          },
        });
        if (errors?.length) {
          this.onError();
        } else {
          this.token = token;
          this.tokenId = id;
        }
      } catch (exception) {
        this.onError(exception);
      }
      this.isCreatingToken = false;
    },
    async validate() {
      try {
        await this.$apollo.mutate({
          mutation: dastSiteValidationCreateMutation,
          variables: {
            fullPath: this.fullPath,
            dastSiteTokenId: this.tokenId,
            validationPath: this.validationPath,
            validationStrategy: this.validationMethod,
          },
        });
      } catch (exception) {
        this.onError(exception);
      }
    },
    onError(exception = null) {
      if (exception !== null) {
        Sentry.captureException(exception);
      }
      this.hasErrors = true;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalProps.id"
    :title="modalProps.title"
    :action-primary="modalProps.primaryProps"
    :action-cancel="modalProps.cancelProps"
    v-bind="$attrs"
    v-on="$listeners"
    @primary="validate"
  >
    <template v-if="isCreatingToken">
      <gl-skeleton-loader :width="768" :height="206">
        <rect y="0" width="300" height="16" rx="4" />
        <rect y="25" width="200" height="16" rx="4" />
        <rect y="65" width="350" height="16" rx="4" />
        <rect y="90" width="535" height="24" rx="4" />
        <rect y="135" width="370" height="16" rx="4" />
        <rect y="160" width="460" height="32" rx="4" />
      </gl-skeleton-loader>
    </template>
    <gl-alert v-else-if="hasErrors" variant="danger" :dismissible="false">
      {{ s__('DastSiteValidation|Could not create validation token. Please try again.') }}
    </gl-alert>
    <template v-else>
      <p>
        {{
          s__(
            'DastSiteValidation|To run an active scan, validate your site. Site profile validation reduces the risk of running an active scan against the wrong website. All site profiles that share the same base URL share the same validation status.',
          )
        }}
        <gl-link :href="helpUrl" target="_blank">{{ __('Learn more.') }}</gl-link>
      </p>
      <gl-form-group :label="s__('DastSiteValidation|Step 1 - Choose site validation method.')">
        <gl-form-radio-group v-model="validationMethod" :options="validationMethodOptions" />
      </gl-form-group>
      <gl-form-group
        v-if="isTextFileValidation"
        :label="
          s__(
            'DastSiteValidation|Step 2 - Download the following text file, then upload it to the target site.',
          )
        "
      >
        <gl-button
          variant="confirm"
          category="secondary"
          size="small"
          icon="download"
          class="gl-display-inline-flex gl-max-w-full"
          data-testid="download-dast-text-file-validation-button"
          :aria-label="s__('DastSiteValidation|Download validation text file')"
          @click="downloadTextFile()"
        >
          <gl-truncate :text="textFileName" position="middle" />
        </gl-button>
      </gl-form-group>
      <gl-form-group
        v-else-if="isHttpHeaderValidation"
        :label="s__('DastSiteValidation|Step 2 - Add the following HTTP header to your site.')"
      >
        <code class="gl-p-3 gl-bg-black gl-text-white">{{ httpHeader }}</code>
        <modal-copy-button
          :text="httpHeader"
          :title="s__('DastSiteValidation|Copy HTTP header to clipboard')"
          :modal-id="modalProps.id"
        />
      </gl-form-group>
      <gl-form-group
        v-else-if="isMetaTagValidation"
        :label="s__('DastSiteValidation|Step 2 - Add the following meta tag to your site.')"
      >
        <code class="gl-p-3 gl-bg-black gl-text-white">{{ metaTag }}</code>
        <modal-copy-button
          :text="metaTag"
          :title="s__('DastSiteValidation|Copy Meta tag to clipboard')"
          :modal-id="modalProps.id"
        />
      </gl-form-group>
      <gl-form-group :label="locationStepLabel" class="gl-max-w-62">
        <gl-form-input-group>
          <template #prepend>
            <gl-input-group-text data-testid="dast-site-validation-path-prefix">{{
              origin
            }}</gl-input-group-text>
          </template>
          <gl-form-input
            v-model="validationPath"
            class="gl-bg-white!"
            data-testid="dast-site-validation-path-input"
            @input="onValidationPathInput()"
          />
        </gl-form-input-group>
      </gl-form-group>
    </template>
  </gl-modal>
</template>
