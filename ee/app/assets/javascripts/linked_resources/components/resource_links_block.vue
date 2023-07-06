<script>
import { GlLink, GlIcon, GlButton, GlLoadingIcon, GlTooltipDirective, GlCard } from '@gitlab/ui';
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
    GlCard,
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
    shouldShowHelpText() {
      return !this.hasResourceLinks && !this.isFetching && !this.isFormVisible;
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
  <div id="resource-links">
    <gl-card
      class="gl-new-card gl-overflow-hidden"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body"
      :aria-expanded="isOpen.toString()"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper">
          <h3 class="gl-new-card-title">
            <gl-link
              id="user-content-resource-links"
              class="anchor gl-absolute gl-text-decoration-none"
              href="#resource-links"
              aria-hidden="true"
            />
            <slot name="header-text">{{ $options.i18n.headerText }}</slot>
          </h3>
          <div class="gl-new-card-count js-related-issues-header-issue-count">
            <gl-icon name="link" class="gl-mr-2" />
            {{ badgeLabel }}
          </div>
        </div>
        <slot name="header-actions"></slot>
        <gl-button
          v-if="canAddResourceLinks"
          size="small"
          :aria-label="$options.i18n.addButtonText"
          class="gl-ml-3"
          data-testid="add-resource-links"
          @click="toggleResourceLinkForm"
        >
          <slot name="add-button-text">{{ __('Add') }}</slot>
        </gl-button>
        <div class="gl-new-card-toggle">
          <gl-button
            category="tertiary"
            size="small"
            :icon="toggleIcon"
            :aria-label="toggleLabel"
            data-testid="toggle-links"
            @click="handleToggle"
          />
        </div>
      </template>
      <div v-if="isOpen" class="linked-issues-card-body gl-new-card-content">
        <div v-show="isFormVisible" class="gl-new-card-add-form">
          <add-issuable-resource-link-form
            ref="resourceLinkForm"
            :is-submitting="isSubmitting"
            @add-issuable-resource-link-form-cancel="hideResourceLinkForm"
            @create-resource-link="onCreateResourceLink"
          />
        </div>
        <div v-if="isFetching" class="gl-new-card-empty">
          <gl-loading-icon
            size="sm"
            :label="$options.i18n.fetchingLinkedResourcesText"
            class="gl-py-4"
          />
        </div>
        <p v-if="shouldShowHelpText" class="gl-new-card-empty" data-testid="empty">
          {{ $options.i18n.helpText }}
        </p>
        <template v-if="hasResourceLinks">
          <resource-links-list
            :can-admin="canAddResourceLinks"
            :resource-links="resourceLinks"
            :is-form-visible="isFormVisible"
            @resourceLinkRemoveRequest="onResourceLinkRemoveRequest"
          />
        </template>
      </div>
    </gl-card>
  </div>
</template>
