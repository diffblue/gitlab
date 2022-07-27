<script>
import { GlLink, GlIcon, GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { produce } from 'immer';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ISSUE } from '~/graphql_shared/constants';
import { createAlert } from '~/flash';
import { sprintf } from '~/locale';
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
          incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
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
    hasBody() {
      return this.isFormVisible;
    },
    hasResourceLinks() {
      return Boolean(this.resourceLinks.length);
    },
    isFetching() {
      return this.$apollo.queries.resourceLinks.loading;
    },
  },
  methods: {
    async toggleResourceLinkForm() {
      this.isFormVisible = !this.isFormVisible;
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
        incidentId: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
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
              id: convertToGraphQLId(TYPE_ISSUE, this.issuableId),
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
        :class="{ 'panel-empty-heading border-bottom-0': !hasBody }"
        class="card-header gl-display-flex gl-justify-content-space-between"
      >
        <h3
          class="card-title h5 position-relative gl-my-0 gl-display-flex gl-align-items-center gl-h-7"
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
            <gl-icon v-gl-tooltip name="question" :size="12" :title="$options.i18n.helpText" />
          </gl-link>

          <div class="gl-display-inline-flex">
            <div class="gl-display-inline-flex gl-mx-5">
              <span class="gl-display-inline-flex gl-align-items-center">
                <gl-icon name="link" class="gl-mr-2 gl-text-gray-500" />
                {{ badgeLabel }}
              </span>
            </div>
            <gl-button
              v-if="canAddResourceLinks"
              icon="plus"
              :aria-label="$options.i18n.addButtonText"
              @click="toggleResourceLinkForm"
            />
          </div>
        </h3>
      </div>
      <div
        class="bg-gray-light"
        :class="{
          'linked-issues-card-body gl-p-5': isFormVisible,
        }"
      >
        <div v-show="isFormVisible" class="card-body bordered-box gl-bg-white">
          <add-issuable-resource-link-form
            ref="resourceLinkForm"
            :is-submitting="isSubmitting"
            @add-issuable-resource-link-form-cancel="hideResourceLinkForm"
            @create-resource-link="onCreateResourceLink"
          />
        </div>
        <div v-if="isFetching" class="gl-mb-2">
          <gl-loading-icon
            size="sm"
            :label="$options.i18n.fetchingLinkedResourcesText"
            class="gl-mt-2"
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
