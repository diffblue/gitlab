<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import createFlash from '~/flash';
import externalAuditEventDestinationCreate from '../../graphql/create_external_destination.mutation.graphql';
import { ADD_STREAM_EDITOR_I18N, AUDIT_STREAMS_NETWORK_ERRORS } from '../../constants';

const { CREATING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;
export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  inject: ['groupPath'],
  data() {
    return { destinationUrl: '', loading: false };
  },
  methods: {
    async addDestinationUrl() {
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: externalAuditEventDestinationCreate,
          variables: {
            destinationUrl: this.destinationUrl,
            fullPath: this.groupPath,
          },
          context: {
            isSingleRequest: true,
          },
        });
        const { errors } = data.externalAuditEventDestinationCreate;
        if (errors.length > 0) {
          createFlash({
            message: errors[0],
          });
        } else {
          this.$emit('added');
        }
      } catch (e) {
        createFlash({
          message: CREATING_ERROR,
        });
      } finally {
        this.loading = false;
      }
    },
  },
  i18n: { ...ADD_STREAM_EDITOR_I18N, CREATING_ERROR },
};
</script>

<template>
  <div class="gl-p-4 gl-bg-white gl-border gl-rounded-base">
    <gl-alert
      :title="$options.i18n.WARNING_TITLE"
      :dismissible="false"
      class="gl-mb-5"
      variant="warning"
    >
      {{ $options.i18n.WARNING_CONTENT }}
    </gl-alert>

    <gl-form @submit.prevent="addDestinationUrl">
      <gl-form-group :label="$options.i18n.DESTINATION_URL_LABEL">
        <gl-form-input v-model="destinationUrl" :placeholder="$options.i18n.PLACEHOLDER" />
      </gl-form-group>
      <div class="gl-display-flex">
        <gl-button
          :disabled="!destinationUrl"
          :loading="loading"
          :name="$options.i18n.ADD_BUTTON_NAME"
          class="gl-mr-3"
          variant="confirm"
          type="submit"
          data-testid="stream-destination-add-button"
          >{{ $options.i18n.ADD_BUTTON_TEXT }}</gl-button
        >
        <gl-button
          :name="$options.i18n.CANCEL_BUTTON_NAME"
          data-testid="stream-destination-cancel-button"
          @click="$emit('cancel')"
          >{{ $options.i18n.CANCEL_BUTTON_TEXT }}</gl-button
        >
      </div>
    </gl-form>
  </div>
</template>
