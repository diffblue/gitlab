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
import { isEmpty } from 'lodash';
import * as Sentry from '@sentry/browser';
import { thWidthPercent } from '~/lib/utils/table_utility';
import externalAuditEventDestinationCreate from '../../graphql/create_external_destination.mutation.graphql';
import externalAuditEventDestinationHeaderCreate from '../../graphql/create_external_destination_header.mutation.graphql';
import externalAuditEventDestinationHeaderUpdate from '../../graphql/update_external_destination_header.mutation.graphql';
import externalAuditEventDestinationHeaderDelete from '../../graphql/delete_external_destination_header.mutation.graphql';
import {
  ADD_STREAM_EDITOR_I18N,
  AUDIT_STREAMS_NETWORK_ERRORS,
  createBlankHeader,
} from '../../constants';
import deleteExternalDestination from '../../graphql/delete_external_destination.mutation.graphql';
import { mapAllMutationErrors, mapItemHeadersToFormData } from '../../utils';

const { CREATING_ERROR, UPDATING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;

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
  props: {
    item: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
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
    isEditing() {
      return !isEmpty(this.item);
    },
    addButtonName() {
      return this.isEditing
        ? ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_NAME
        : ADD_STREAM_EDITOR_I18N.ADD_BUTTON_NAME;
    },
    addButtonText() {
      return this.isEditing
        ? ADD_STREAM_EDITOR_I18N.SAVE_BUTTON_TEXT
        : ADD_STREAM_EDITOR_I18N.ADD_BUTTON_TEXT;
    },
  },
  mounted() {
    const existingHeaders = mapItemHeadersToFormData(this.item, { deletionDisabled: false });

    if (existingHeaders.length < this.maxHeaders) {
      existingHeaders.push(createBlankHeader());
    }

    this.headers = existingHeaders;

    this.destinationUrl = this.item.destinationUrl;
  },
  methods: {
    clearError(index) {
      this.errors.splice(index, 1);
    },
    async addDestinationUrl() {
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

      return data.externalAuditEventDestinationCreate;
    },
    async addDestinationHeaders(destinationId, headers) {
      const mutations = headers
        .filter((header) => this.isHeaderFilled(header))
        .map((header) => {
          return this.$apollo.mutate({
            mutation: externalAuditEventDestinationHeaderCreate,
            variables: {
              destinationId,
              key: header.name,
              value: header.value,
            },
          });
        });

      return mapAllMutationErrors(mutations, 'auditEventsStreamingHeadersCreate');
    },
    async updateDestinationHeaders(headers) {
      const mutations = headers
        .filter((header) => this.isHeaderFilled(header))
        .map((header) => {
          return this.$apollo.mutate({
            mutation: externalAuditEventDestinationHeaderUpdate,
            variables: {
              headerId: header.id,
              key: header.name,
              value: header.value,
            },
          });
        });

      return mapAllMutationErrors(mutations, 'auditEventsStreamingHeadersUpdate');
    },
    async deleteDestinationHeaders(headers) {
      const mutations = headers
        .filter((header) => this.isHeaderFilled(header))
        .map((header) => {
          return this.$apollo.mutate({
            mutation: externalAuditEventDestinationHeaderDelete,
            variables: {
              headerId: header.id,
            },
          });
        });

      return mapAllMutationErrors(mutations, 'auditEventsStreamingHeadersDestroy');
    },
    async deleteCreatedDestination(destinationId) {
      return this.$apollo.mutate({
        mutation: deleteExternalDestination,
        variables: {
          id: destinationId,
        },
        context: {
          isSingleRequest: true,
        },
      });
    },
    findHeadersToDelete(existingHeaders, changedHeaders) {
      return existingHeaders.filter(
        (existingHeader) =>
          !changedHeaders.some((changedHeader) => existingHeader.id === changedHeader.id),
      );
    },
    findHeadersToUpdate(existingHeaders, changedHeaders) {
      return changedHeaders.filter((changedHeader) =>
        existingHeaders.some(
          (existingHeader) =>
            changedHeader.id === existingHeader.id &&
            (changedHeader.name !== existingHeader.name ||
              changedHeader.value !== existingHeader.value),
        ),
      );
    },
    findHeadersToAdd(existingHeaders, changedHeaders) {
      return changedHeaders.filter((header) => header.id === null && this.isHeaderFilled(header));
    },
    async addDestination() {
      let destinationId = null;

      this.errors = [];
      this.loading = true;

      try {
        const {
          errors = [],
          externalAuditEventDestination: { id },
        } = await this.addDestinationUrl();

        destinationId = id;

        if (!errors.length) {
          errors.push(...(await this.addDestinationHeaders(destinationId, this.headers)));

          if (errors.length > 0) {
            await this.deleteCreatedDestination(destinationId);
          }
        }

        if (errors.length > 0) {
          this.errors.push(...errors);
        } else {
          this.$emit('added');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(CREATING_ERROR);

        if (destinationId) {
          await this.deleteCreatedDestination(destinationId);
        }
      } finally {
        this.loading = false;
      }
    },
    async updateDestination() {
      this.errors = [];
      this.loading = true;
      const existingHeaders = mapItemHeadersToFormData(this.item);
      const changedHeaders = this.headers.filter(
        (header) => header.name !== '' && header.value !== '',
      );

      try {
        const errors = [];

        if (existingHeaders.length > 0) {
          const headersToDelete = this.findHeadersToDelete(existingHeaders, changedHeaders);
          const headersToUpdate = this.findHeadersToUpdate(existingHeaders, changedHeaders);

          errors.push(...(await this.deleteDestinationHeaders(headersToDelete)));
          errors.push(...(await this.updateDestinationHeaders(headersToUpdate)));
        }

        const headersToAdd = this.findHeadersToAdd(existingHeaders, changedHeaders);

        errors.push(...(await this.addDestinationHeaders(this.item.id, headersToAdd)));

        if (errors.length > 0) {
          this.errors.push(...errors);
        } else {
          this.$emit('updated');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(UPDATING_ERROR);
      } finally {
        this.loading = false;
      }
    },
    isHeaderFilled(header) {
      return header.name !== '' && header.value !== '';
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
      thClass: `${thClasses} ${thWidthPercent(10)}`,
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
  <div class="gl-bg-white">
    <gl-alert
      v-if="!isEditing"
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
      @dismiss="clearError(index)"
    >
      {{ error }}
    </gl-alert>

    <gl-form @submit.prevent="() => (isEditing ? updateDestination() : addDestination())">
      <gl-form-group
        :label="$options.i18n.DESTINATION_URL_LABEL"
        data-testid="destination-url-form-group"
      >
        <gl-form-input
          v-model="destinationUrl"
          :placeholder="$options.i18n.DESTINATION_URL_PLACEHOLDER"
          :disabled="isEditing"
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
          :name="addButtonName"
          class="gl-mr-3"
          variant="confirm"
          type="submit"
          data-testid="stream-destination-add-button"
          >{{ addButtonText }}</gl-button
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
