<script>
import { GlIcon, GlLink, GlButton, GlCollapse, GlBadge } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import codeOwnersInfoQuery from '../../../graphql_shared/queries/code_owners_info.query.graphql';

export const i18n = {
  title: s__('CodeOwners|Code owners'),
  and: __('and'),
  errorMessage: s__('CodeOwners|An error occurred while loading code owners.'),
  manageBranchRules: __('Manage branch rules'),
  noCodeOwnersText: s__(
    'CodeOwners|Assign users and groups as approvers for specific file changes.',
  ),
  learnMore: s__('CodeOwners|Learn more.'),
  showAll: s__('CodeOwners|Show all'),
  hideAll: s__('CodeOwners|Hide all'),
};

export const codeOwnersHelpPath = helpPagePath('user/project/codeowners/index.md');

export default {
  i18n,
  codeOwnersHelpPath,
  components: {
    GlIcon,
    GlLink,
    GlButton,
    GlBadge,
    GlCollapse,
  },
  apollo: {
    project: {
      query: codeOwnersInfoQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.filePath,
          ref: this.branch,
        };
      },
      skip() {
        return !this.filePath;
      },
      error() {
        createAlert({ message: this.$options.i18n.errorMessage });
      },
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: false,
      default: '',
    },
    branch: {
      type: String,
      required: false,
      default: '',
    },
    canViewBranchRules: {
      type: Boolean,
      required: false,
      default: false,
    },
    branchRulesPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isCodeOwnersExpanded: false,
      project: {},
    };
  },
  computed: {
    blobInfo() {
      return this.project?.repository?.blobs?.nodes[0];
    },
    collapseIcon() {
      return this.isCodeOwnersExpanded ? 'chevron-down' : 'chevron-right';
    },
    codeOwnersPath() {
      return this.project?.repository?.codeOwnersPath;
    },
    codeOwners() {
      return this.blobInfo?.codeOwners || [];
    },
    codeOwnersTotal() {
      return this.blobInfo?.codeOwners?.length;
    },
    lastIndexOfCodeOwners() {
      return this.codeOwnersTotal - 1;
    },
    toggleText() {
      return this.isCodeOwnersExpanded ? this.$options.i18n.hideAll : this.$options.i18n.showAll;
    },
    hasCodeOwners() {
      return this.filePath && Boolean(this.codeOwners.length);
    },
    commaSeparateList() {
      return this.codeOwners.length > 1;
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
  },
  watch: {
    filePath() {
      this.$apollo.queries.project.refetch();
    },
  },
  methods: {
    toggleCodeOwners() {
      this.isCodeOwnersExpanded = !this.isCodeOwnersExpanded;
    },
  },
};
</script>

<template>
  <div
    v-if="filePath"
    class="well-segment blob-auxiliary-viewer file-owner-content gl-display-flex gl-justify-content-space-between gl-align-items-flex-start"
  >
    <div class="gl-display-flex gl-flex-wrap">
      <div class="gl-mr-2 gl-mb-2">
        <gl-icon name="users" data-testid="users-icon" />
        <component
          :is="hasCodeOwners ? 'gl-link' : 'span'"
          class="gl-font-weight-bold gl-text-black-normal!"
          :href="codeOwnersPath"
          data-testid="codeowners-file-link"
          >{{ $options.i18n.title }}
        </component>
      </div>
      <div v-if="!hasCodeOwners && !isLoading">
        <span data-testid="no-codeowners-text">{{ $options.i18n.noCodeOwnersText }}</span>
        <gl-link
          data-testid="codeowners-docs-link"
          target="_blank"
          :href="$options.codeOwnersHelpPath"
          >{{ $options.i18n.learnMore }}</gl-link
        >
      </div>

      <template v-if="hasCodeOwners && !isLoading">
        <gl-badge class="gl-mx-2 gl-mb-2" size="sm">{{ codeOwnersTotal }}</gl-badge>
        <gl-button
          class="gl-mb-2 gl-w-12"
          variant="link"
          data-testid="collapse-toggle"
          @click="toggleCodeOwners"
        >
          <gl-icon :name="collapseIcon" />
          {{ toggleText }}
        </gl-button>
        <gl-collapse :visible="isCodeOwnersExpanded" class="gl-ml-2">
          <div
            v-for="(owner, index) in codeOwners"
            :key="owner.id"
            class="gl-display-inline-block"
            data-testid="code-owners"
          >
            <span
              v-if="commaSeparateList && index === lastIndexOfCodeOwners"
              data-testid="and-separator"
              class="gl-ml-2"
              >{{ $options.i18n.and }}</span
            >
            <span
              v-if="commaSeparateList && index !== 0 && index !== lastIndexOfCodeOwners"
              data-testid="comma-separator"
              >,
            </span>
            <gl-link :href="owner.webPath" target="_blank">
              {{ owner.name }}
            </gl-link>
          </div>
        </gl-collapse>
      </template>
    </div>
    <gl-button
      v-if="canViewBranchRules"
      size="small"
      :href="branchRulesPath"
      class="gl-ml-4"
      data-testid="branch-rules-link"
    >
      {{ $options.i18n.manageBranchRules }}
    </gl-button>
  </div>
</template>
