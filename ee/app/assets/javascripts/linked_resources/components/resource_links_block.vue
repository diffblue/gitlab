<script>
import { GlLink, GlIcon, GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { produce } from 'immer';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ISSUE } from '~/graphql_shared/constants';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import { resourceLinksI18n } from '../constants';
import { displayAndLogError, identifyLinkType } from './utils';
import getIssuableResourceLinks from './graphql/queries/get_issuable_resource_links.query.graphql';
import deleteIssuableRsourceLink from './graphql/queries/delete_issuable_resource_link.mutation.graphql';
import createIssuableResourceLink from './graphql/queries/create_issuable_resource_link.mutation.graphql';
import AddIssuableResourceLinkForm from './add_issuable_resource_link_form.vue';
import ResourceLinksList from './resource_links_list.vue';

export default {
  name: 'ResourceLinksBlock',
  components: {
    GlLink,
    GlButton,
    GlIcon,
    AddIssuableResourceLinkForm,
    ResourceLinksList,
    GlLoadingIcon,
  },
  i18n: resourceLinksI18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issuableId: {
      type: Number,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    canAddResourceLinks: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isOpen: true,
      isFormVisible: false,
      isSubmitting: false,
      resourceLinks: [],
    };
  },
  apollo: {
    resourceLinks: {
      query: getIssuableResourceLinks,
      variables() {
        return {
          incidentId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
        };
      },
      update(data) {
        return data?.issue?.issuableResourceLinks?.nodes;
      },
      error(error) {
        displayAndLogError(error);
      },
    },
  },
  computed: {
    badgeLabel() {
      return this.isFetching && this.resourceLinks.length === 0 ? '...' : this.resourceLinks.length;
    },
    hasResourceLinks() {
      return Boolean(this.resourceLinks.length);
    },
    isFetching() {
      return this.$apollo.queries.resourceLinks.loading;
    },
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? __('Collapse') : __('Expand');
    },
  },
  methods: {
    handleToggle() {
      this.isOpen = !this.isOpen;
      if (!this.isOpen) {
        this.isFormVisible = false;
      }
    },
    async toggleResourceLinkForm() {
      this.isFormVisible = !this.isFormVisible;
      this.isOpen = true;
    },
    hideResourceLinkForm() {
      this.isFormVisible = false;
    },
    async onResourceLinkRemoveRequest(linkToRemove) {
      try {
        const result = await this.$apollo.mutate({
          mutation: deleteIssuableRsourceLink,
          variables: {
            input: {
              id: linkToRemove,
            },
          },
          update: () => {
            this.resourceLinks = this.resourceLinks.filter((link) => link.id !== linkToRemove);
          },
        });
        const { errors } = result.data.issuableResourceLinkDestroy;
        if (errors?.length) {
          const errorMessage = sprintf(this.$options.i18n.deleteError, {
            error: errors.join('. '),
          });
          throw new Error(errorMessage);
        }
      } catch (error) {
        const message = error.message || this.$options.i18n.deleteErrorGeneric;
        let captureError = false;
        let errorObj = null;

        if (message === this.$options.i18n.deleteErrorGeneric) {
          captureError = true;
          errorObj = error;
        }

        createAlert({
          message,
          captureError,
          error: errorObj,
        });
      }
    },
    updateCache(store, { data }) {
      const { issuableResourceLink: resourceLink, errors } = data?.issuableResourceLinkCreate || {};
      if (errors.length) {
        return;
      }

      const variables = {
        incidentId: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
      };

      const sourceData = store.readQuery({
        query: getIssuableResourceLinks,
        variables,
      });

      const newData = produce(sourceData, (draftData) => {
        const { nodes: draftLinkList } = draftData.issue.issuableResourceLinks;
        draftLinkList.push(resourceLink);
        draftData.issue.issuableResourceLinks.nodes = draftLinkList;
      });

      store.writeQuery({
        query: getIssuableResourceLinks,
        variables,
        data: newData,
      });
    },
    onCreateResourceLink(resourceLink) {
      this.isSubmitting = true;
      return this.$apollo
        .mutate({
          mutation: createIssuableResourceLink,
          variables: {
            input: {
              ...resourceLink,
              id: convertToGraphQLId(TYPENAME_ISSUE, this.issuableId),
              linkType: identifyLinkType(resourceLink.link),
            },
          },
          update: this.updateCache,
        })
        .then(({ data = {} }) => {
          const errors = data.issuableResourceLinkCreate?.errors;
          if (errors.length) {
            const errorMessage = sprintf(
              this.$options.i18n.createError,
              { error: errors.join('. ') },
              false,
            );
            throw new Error(errorMessage);
          }
        })
        .catch((error) => {
          const message = error.message || this.$options.i18n.createErrorGeneric;
          let captureError = false;
          let errorObj = null;

          if (message === this.$options.i18n.createErrorGeneric) {
            captureError = true;
            errorObj = error;
          }

          createAlert({
            message,
            captureError,
            error: errorObj,
          });
        })
        .finally(() => {
          this.isSubmitting = false;
          this.$refs.resourceLinkForm.onFormCancel();
        });
    },
  },
};
</script>

<template>
  <div id="resource-links" class="gl-mt-5">
    <div class="card card-slim gl-overflow-hidden">
      <div
        :class="{ 'panel-empty-heading border-bottom-0': !isFormVisible, 'gl-border-b-1': !isOpen }"
        class="card-header gl-display-flex gl-justify-content-space-between gl-bg-white gl-align-items-center gl-line-height-24 gl-pl-5 gl-pr-4 gl-py-4"
      >
        <h3
          class="card-title h5 position-relative gl-my-0 gl-display-flex gl-align-items-center gl-line-height-24"
        >
          <gl-link
            id="user-content-resource-links"
            class="anchor position-absolute gl-text-decoration-none"
            href="#resource-links"
            aria-hidden="true"
          />
          <slot name="header-text">{{ $options.i18n.headerText }}</slot>
          <gl-link
            :href="helpPath"
            target="_blank"
            class="gl-display-flex gl-align-items-center gl-ml-2 gl-text-gray-500"
            data-testid="help-link"
            :aria-label="$options.i18n.helpText"
          >
            <gl-icon
              v-gl-tooltip
              name="question-o"
              :size="14"
              :title="$options.i18n.helpText"
              class="gl-text-blue-500"
            />
          </gl-link>

          <div class="gl-display-inline-flex">
            <div class="gl-display-inline-flex gl-mx-3">
              <span class="gl-display-inline-flex gl-align-items-center gl-text-gray-500">
                <gl-icon name="link" class="gl-mr-2" />
                {{ badgeLabel }}
              </span>
            </div>
          </div>
        </h3>
        <slot name="header-actions"></slot>
        <gl-button
          v-if="canAddResourceLinks"
          size="small"
          :aria-label="$options.i18n.addButtonText"
          class="gl-ml-auto"
          data-testid="add-resource-links"
          @click="toggleResourceLinkForm"
        >
          <slot name="add-button-text">{{ __('Add') }}</slot>
        </gl-button>
        <div class="gl-pl-3 gl-ml-3 gl-border-l-1 gl-border-l-solid gl-border-l-gray-100">
          <gl-button
            category="tertiary"
            size="small"
            :icon="toggleIcon"
            :aria-label="toggleLabel"
            :disabled="!hasResourceLinks"
            data-testid="toggle-links"
            @click="handleToggle"
          />
        </div>
      </div>
      <div
        v-if="isOpen"
        class="gl-bg-gray-10"
        :class="{
          'linked-issues-card-body': isFormVisible,
        }"
      >
        <div v-show="isFormVisible" class="card-body bordered-box gl-bg-white gl-mt-4 gl-mx-4">
          <add-issuable-resource-link-form
            ref="resourceLinkForm"
            :is-submitting="isSubmitting"
            @add-issuable-resource-link-form-cancel="hideResourceLinkForm"
            @create-resource-link="onCreateResourceLink"
          />
        </div>
        <div v-if="isFetching" class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100">
          <gl-loading-icon
            size="sm"
            :label="$options.i18n.fetchingLinkedResourcesText"
            class="gl-py-4"
          />
        </div>
        <template v-if="hasResourceLinks">
          <resource-links-list
            :can-admin="canAddResourceLinks"
            :resource-links="resourceLinks"
            :is-form-visible="isFormVisible"
            @resourceLinkRemoveRequest="onResourceLinkRemoveRequest"
          />
        </template>
      </div>
    </div>
  </div>
</template>
