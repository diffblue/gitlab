<script>
import {
  GlAccordion,
  GlAccordionItem,
  GlAlert,
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlSprintf,
  GlTableLite,
} from '@gitlab/ui';
import { isEmpty, isEqual } from 'lodash';
import * as Sentry from '@sentry/browser';
import { GlTooltipDirective as GlTooltip } from '@gitlab/ui/dist/directives/tooltip';
import { thWidthPercent } from '~/lib/utils/table_utility';
import externalAuditEventDestinationCreate from '../../graphql/mutations/create_external_destination.mutation.graphql';
import deleteExternalDestination from '../../graphql/mutations/delete_external_destination.mutation.graphql';
import externalAuditEventDestinationHeaderCreate from '../../graphql/mutations/create_external_destination_header.mutation.graphql';
import externalAuditEventDestinationHeaderUpdate from '../../graphql/mutations/update_external_destination_header.mutation.graphql';
import externalAuditEventDestinationHeaderDelete from '../../graphql/mutations/delete_external_destination_header.mutation.graphql';
import deleteExternalDestinationFilters from '../../graphql/mutations/delete_external_destination_filters.mutation.graphql';
import updateExternalDestinationFilters from '../../graphql/mutations/update_external_destination_filters.mutation.graphql';
import {
  ADD_STREAM_EDITOR_I18N,
  AUDIT_STREAMS_NETWORK_ERRORS,
  createBlankHeader,
} from '../../constants';
import {
  addAuditEventsStreamingDestination,
  removeAuditEventsStreamingDestination,
  addAuditEventStreamingHeader,
  removeAuditEventStreamingHeader,
  updateEventTypeFilters,
  removeEventTypeFilters,
} from '../../graphql/cache_update';
import { mapAllMutationErrors, mapItemHeadersToFormData } from '../../utils';
import StreamFilters from './stream_filters.vue';

const { CREATING_ERROR, UPDATING_ERROR } = AUDIT_STREAMS_NETWORK_ERRORS;

const thClasses = `gl-border-top-0! gl-p-3!`;
const tdClasses = `gl-p-3!`;

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
    GlTableLite,
    StreamFilters,
  },
  directives: {
    GlTooltip,
  },
  inject: ['groupPath', 'maxHeaders'],
  props: {
    item: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    groupEventFilters: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      destinationUrl: '',
      errors: [],
      loading: false,
      headers: [createBlankHeader()],
      filters: [],
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
    itemFilters() {
      return this.item?.eventTypeFilters || [];
    },
  },
  mounted() {
    const existingHeaders = mapItemHeadersToFormData(this.item);

    if (existingHeaders.length < this.maxHeaders) {
      existingHeaders.push(createBlankHeader());
    }

    this.headers = existingHeaders;

    this.destinationUrl = this.item.destinationUrl;

    this.filters = this.item.eventTypeFilters;
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
        update(cache, { data: updateData }, args) {
          if (updateData.externalAuditEventDestinationCreate.errors.length) {
            return;
          }
          addAuditEventsStreamingDestination({
            store: cache,
            fullPath: args.variables.fullPath,
            newDestination:
              updateData.externalAuditEventDestinationCreate.externalAuditEventDestination,
          });
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
            update(cache, { data }) {
              if (data.auditEventsStreamingHeadersCreate.errors.length) {
                return;
              }

              addAuditEventStreamingHeader({
                store: cache,
                destinationId,
                newHeader: data.auditEventsStreamingHeadersCreate.header,
              });
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
      const { id: destinationId } = this.item;
      const mutations = headers
        .filter((header) => this.isHeaderFilled(header))
        .map((header) => {
          return this.$apollo.mutate({
            mutation: externalAuditEventDestinationHeaderDelete,
            variables: {
              headerId: header.id,
            },
            update(cache, { data }) {
              if (data.auditEventsStreamingHeadersDestroy.errors.length) {
                return;
              }

              removeAuditEventStreamingHeader({
                store: cache,
                destinationId,
                headerId: header.id,
              });
            },
          });
        });

      return mapAllMutationErrors(mutations, 'auditEventsStreamingHeadersDestroy');
    },
    async deleteCreatedDestination(destinationId) {
      const { groupPath: fullPath } = this;
      return this.$apollo.mutate({
        mutation: deleteExternalDestination,
        variables: {
          id: destinationId,
        },
        context: {
          isSingleRequest: true,
        },
        update(cache, { data }) {
          if (data.externalAuditEventDestinationDestroy.errors.length) {
            return;
          }

          removeAuditEventsStreamingDestination({
            store: cache,
            fullPath,
            destinationId,
          });
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
    async removeDestinationFilters(destinationId, filters) {
      const { data } = await this.$apollo.mutate({
        mutation: deleteExternalDestinationFilters,
        variables: {
          destinationId,
          eventTypeFilters: filters,
        },
        update(cache, { data: updateData }) {
          if (updateData.auditEventsStreamingDestinationEventsRemove.errors.length) {
            return;
          }

          removeEventTypeFilters({
            store: cache,
            destinationId,
            filtersToRemove: filters,
          });
        },
      });
      const error = data.auditEventsStreamingDestinationEventsRemove.errors || [];

      return error;
    },
    async addDestinationFilters(destinationId, filters) {
      const { data } = await this.$apollo.mutate({
        mutation: updateExternalDestinationFilters,
        variables: {
          destinationId,
          eventTypeFilters: filters,
        },
        update(cache, { data: updateData }) {
          if (updateData.auditEventsStreamingDestinationEventsAdd.errors.length) {
            return;
          }

          updateEventTypeFilters({
            store: cache,
            destinationId,
            filters,
          });
        },
      });
      const error = data.auditEventsStreamingDestinationEventsAdd.errors || [];

      return error;
    },
    async addDestination() {
      let destinationId = null;

      this.errors = [];
      this.loading = true;

      try {
        const errors = [];
        const {
          errors: destinationErrors = [],
          externalAuditEventDestination,
        } = await this.addDestinationUrl();
        errors.push(...destinationErrors);
        destinationId = externalAuditEventDestination?.id;

        if (!errors.length) {
          errors.push(...(await this.addDestinationHeaders(destinationId, this.headers)));

          if (errors.length > 0) {
            await this.deleteCreatedDestination(destinationId);
          }
        }

        if (this.filters?.length > 0 && destinationId) {
          const addDestinationFiltersErrors = await this.addDestinationFilters(
            destinationId,
            this.filters,
          );
          errors.push(...addDestinationFiltersErrors);
        }

        if (errors.length > 0) {
          this.errors.push(...errors);
          this.$emit('error');
        } else {
          this.$emit('added');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(CREATING_ERROR);
        this.$emit('error');

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

        if (!isEqual(this.item.eventTypeFilters, this.filters)) {
          const removeFilters = this.item.eventTypeFilters.filter((f) => !this.filters.includes(f));
          const addFilters = this.filters.filter((f) => !this.item.eventTypeFilters.includes(f));
          if (removeFilters?.length) {
            const removeDestinationFiltersErrors = await this.removeDestinationFilters(
              this.item.id,
              removeFilters,
            );
            errors.push(...removeDestinationFiltersErrors);
          }
          if (addFilters?.length) {
            const addDestinationFiltersErrors = await this.addDestinationFilters(
              this.item.id,
              addFilters,
            );
            errors.push(...addDestinationFiltersErrors);
          }
        }

        if (errors.length > 0) {
          this.errors.push(...errors);
          this.$emit('error');
        } else {
          this.$emit('updated');
        }
      } catch (e) {
        Sentry.captureException(e);
        this.errors.push(UPDATING_ERROR);
        this.$emit('error');
      } finally {
        this.loading = false;
      }
    },
    isHeaderFilled(header) {
      return header.name !== '' && header.value !== '';
    },
    headerNameExists(value) {
      return this.headers.some((header) => header.name === value);
    },
    addBlankHeader(headerProps = {}) {
      if (!this.hasReachedMaxHeaders) {
        this.headers.push({ ...createBlankHeader(), ...headerProps });
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
        };

        this.$set(this.headers, index, updatedHeader);
      }
    },
    handleHeaderValueInput(index, value) {
      this.$set(this.headers, index, { ...this.headers[index], value });
    },
    handleHeaderActiveInput(index, active) {
      this.$set(this.headers, index, { ...this.headers[index], active });
    },
    removeHeader(index) {
      this.headers.splice(index, 1);
      const headersCount = this.headers.length;

      // Add a new blank row if headers is now empty
      if (headersCount === 0) {
        this.addBlankHeader({ deletionDisabled: true });
      }
    },
    updateEventTypeFilters(newFilters) {
      this.filters = newFilters;
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
      tdClass: tdClasses,
    },
  ],
};
</script>

<template>
  <div>
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

      <div class="gl-mb-5">
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
              v-gl-tooltip
              :aria-label="$options.i18n.REMOVE_BUTTON_LABEL"
              :title="$options.i18n.REMOVE_BUTTON_TOOLTIP"
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
        <gl-button
          v-else
          :loading="loading"
          :name="$options.i18n.ADD_HEADER_ROW_BUTTON_NAME"
          class="gl-mx-3"
          variant="confirm"
          category="secondary"
          size="small"
          data-testid="add-header-row-button"
          @click="addBlankHeader()"
        >
          {{ $options.i18n.ADD_HEADER_ROW_BUTTON_TEXT }}
        </gl-button>
      </div>

      <div class="gl-mb-5">
        <strong class="gl-display-block gl-mb-3" data-testid="filtering-header">{{
          $options.i18n.HEADER_FILTERING
        }}</strong>

        <gl-accordion :header-level="1">
          <gl-accordion-item :title="$options.i18n.HEADER_FILTERING_ITEM">
            <div v-if="groupEventFilters.length">
              <p data-testid="filtering-subheader">{{ $options.i18n.SUBHEADER_FILTERING }}</p>
              <stream-filters
                :filter-options="groupEventFilters"
                :filter-selected="itemFilters"
                @updateFilters="updateEventTypeFilters"
              />
            </div>
            <div v-else>
              <gl-sprintf :message="$options.i18n.SUBHEADER_EMPTY_FILTERING">
                <template #link="{ content }">
                  <gl-link
                    :href="$options.i18n.SUBHEADER_EMPTY_FILTERING_LINK"
                    class="gl-text-blue-500!"
                    >{{ content }}</gl-link
                  >
                </template>
              </gl-sprintf>
            </div>
          </gl-accordion-item>
        </gl-accordion>
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
