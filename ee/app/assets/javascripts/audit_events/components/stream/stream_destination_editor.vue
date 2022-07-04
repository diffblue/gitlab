<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlSprintf,
  GlTableLite,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { thWidthPercent } from '~/lib/utils/table_utility';
import externalAuditEventDestinationCreate from '../../graphql/create_external_destination.mutation.graphql';
import {
  ADD_STREAM_EDITOR_I18N,
  AUDIT_STREAMS_NETWORK_ERRORS,
  createBlankHeader,
} from '../../constants';

const { CREATING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;

const thClasses = `gl-border-top-0! gl-p-3!`;
const tdClasses = `gl-p-3!`;

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
    GlTableLite,
  },
  inject: ['groupPath', 'showStreamsHeaders', 'maxHeaders'],
  data() {
    return {
      destinationUrl: '',
      errors: [],
      loading: false,
      headers: [createBlankHeader()],
    };
  },
  computed: {
    hasReachedMaxHeaders() {
      return this.headers.length >= this.maxHeaders;
    },
    hasHeaderValidationErrors() {
      return this.headers.some((header) => header.validationErrors.name !== '');
    },
    hasMissingKeyValuePairs() {
      return this.headers.some(
        (header) =>
          (header.name !== '' && header.value === '') ||
          (header.name === '' && header.value !== ''),
      );
    },
    isSubmitButtonDisabled() {
      return !this.destinationUrl || this.hasHeaderValidationErrors || this.hasMissingKeyValuePairs;
    },
  },
  methods: {
    async addDestinationUrl() {
      this.errors = [];
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
          this.errors.push(errors[0]);
        } else {
          this.$emit('added');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(CREATING_ERROR);
      } finally {
        this.loading = false;
      }
    },
    isRowFilled(index) {
      return this.headers[index].name !== '' && this.headers[index].value !== '';
    },
    isLastRow(index) {
      return this.headers.length === index + 1;
    },
    headerNameExists(value) {
      return this.headers.some((header) => header.name === value);
    },
    addBlankHeader() {
      this.headers.push(createBlankHeader());
    },
    addBlankRowIfNeeded(index) {
      if (!this.hasReachedMaxHeaders && this.isRowFilled(index) && this.isLastRow(index)) {
        this.addBlankHeader();
      }
    },
    handleHeaderNameInput(index, name) {
      const header = this.headers[index];

      if (name !== '' && this.headerNameExists(name)) {
        header.validationErrors.name = ADD_STREAM_EDITOR_I18N.HEADER_INPUT_DUPLICATE_ERROR;
      } else {
        const updatedHeader = {
          ...header,
          name,
          validationErrors: {
            ...header.validationErrors,
            name: '',
          },
          deletionDisabled: false,
        };

        this.$set(this.headers, index, updatedHeader);
      }

      this.addBlankRowIfNeeded(index);
    },
    handleHeaderValueInput(index, value) {
      this.$set(this.headers, index, { ...this.headers[index], value, deletionDisabled: false });
      this.addBlankRowIfNeeded(index);
    },
    handleHeaderActiveInput(index, active) {
      this.$set(this.headers, index, { ...this.headers[index], active });
    },
    removeHeader(index) {
      this.headers.splice(index, 1);
      const headersCount = this.headers.length;

      // Add a new blank row if headers is now empty or the last row is filled out
      if (headersCount === 0 || this.isRowFilled(headersCount - 1)) {
        this.addBlankHeader();
      }
    },
  },
  i18n: { ...ADD_STREAM_EDITOR_I18N, CREATING_ERROR },
  fields: [
    {
      key: 'name',
      label: ADD_STREAM_EDITOR_I18N.TABLE_COLUMN_NAME_LABEL,
      thClass: `${thClasses} ${thWidthPercent(40)}`,
      tdClass: tdClasses,
    },
    {
      key: 'value',
      label: ADD_STREAM_EDITOR_I18N.TABLE_COLUMN_VALUE_LABEL,
      thClass: `${thClasses} ${thWidthPercent(50)}`,
      tdClass: tdClasses,
    },
    {
      key: 'active',
      label: ADD_STREAM_EDITOR_I18N.TABLE_COLUMN_ACTIVE_LABEL,
      thClass: `${thClasses} ${thWidthPercent(5)}`,
      tdClass: tdClasses,
    },
    {
      key: 'actions',
      label: '',
      thClass: thClasses,
      tdClass: `${tdClasses} gl-text-right`,
    },
  ],
};
</script>

<template>
  <div class="gl-p-4 gl-bg-white gl-border gl-rounded-base">
    <gl-alert
      :title="$options.i18n.WARNING_TITLE"
      :dismissible="false"
      class="gl-mb-5"
      data-testid="data-warning"
      variant="warning"
    >
      {{ $options.i18n.WARNING_CONTENT }}
    </gl-alert>

    <gl-alert
      v-for="(error, index) in errors"
      :key="index"
      :dismissible="true"
      class="gl-mb-5"
      data-testid="alert-errors"
      variant="danger"
    >
      {{ error }}
    </gl-alert>

    <gl-form @submit.prevent="addDestinationUrl">
      <gl-form-group
        :label="$options.i18n.DESTINATION_URL_LABEL"
        data-testid="destination-url-form-group"
      >
        <gl-form-input
          v-model="destinationUrl"
          :placeholder="$options.i18n.DESTINATION_URL_PLACEHOLDER"
          data-testid="destination-url"
        />
      </gl-form-group>

      <div v-if="showStreamsHeaders" class="gl-mb-5">
        <strong class="gl-display-block gl-mb-3">{{ $options.i18n.HEADERS_LABEL }}</strong>
        <gl-table-lite :items="headers" :fields="$options.fields">
          <template
            #cell(name)="{
              index,
              item: {
                disabled,
                validationErrors: { name: feedback = '' },
                name,
              },
            }"
          >
            <gl-form-group
              class="gl-m-0"
              label-class="gl-m-0! gl-p-0!"
              :invalid-feedback="feedback"
            >
              <gl-form-input
                :value="name"
                :placeholder="$options.i18n.HEADER_INPUT_PLACEHOLDER"
                :disabled="disabled"
                :state="feedback === ''"
                data-testid="header-name-input"
                @input="handleHeaderNameInput(index, $event)"
              />
            </gl-form-group>
          </template>
          <template #cell(value)="{ index, item: { disabled, value } }">
            <gl-form-group class="gl-m-0" label-class="gl-m-0! gl-p-0!">
              <gl-form-input
                :value="value"
                :placeholder="$options.i18n.VALUE_INPUT_PLACEHOLDER"
                :disabled="disabled"
                data-testid="header-value-input"
                @input="handleHeaderValueInput(index, $event)"
              />
            </gl-form-group>
          </template>
          <template #cell(active)="{ index, item: { active } }">
            <gl-form-checkbox
              class="gl-mt-3"
              :checked="active"
              :disabled="true"
              @input="handleHeaderActiveInput(index, $event)"
            />
          </template>
          <template #cell(actions)="{ index, item: { deletionDisabled } }">
            <gl-button
              category="tertiary"
              icon="remove"
              :disabled="deletionDisabled"
              @click="removeHeader(index)"
            />
          </template>
        </gl-table-lite>
        <p
          v-if="hasReachedMaxHeaders"
          class="gl-mt-5 gl-mb-0 gl-text-gray-500"
          data-testid="maximum-headers"
        >
          <gl-sprintf :message="$options.i18n.MAXIMUM_HEADERS_TEXT">
            <template #number>
              {{ maxHeaders }}
            </template>
          </gl-sprintf>
        </p>
      </div>

      <div class="gl-display-flex">
        <gl-button
          :disabled="isSubmitButtonDisabled"
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
