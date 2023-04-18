<script>
import { GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import codeOwnersInfoQuery from '../../../graphql_shared/queries/code_owners_info.query.graphql';

export default {
  i18n: {
    title: __('Code owners'),
    about: __('About this feature'),
    and: __('and'),
    errorMessage: __('An error occurred while loading code owners.'),
    manageBranchRules: __('Manage branch rules'),
  },
  codeOwnersHelpPath: helpPagePath('user/project/code_owners'),
  components: {
    GlIcon,
    GlLink,
    GlButton,
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
      result() {
        this.isFetching = false;
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
      isFetching: false,
      isCodeOwnersExpanded: false,
      project: {},
    };
  },
  computed: {
    blobInfo() {
      return this.project?.repository?.blobs?.nodes[0];
    },
    codeOwnersPath() {
      return this.project?.repository?.codeOwnersPath;
    },
    visibleCodeOwners() {
      return this.blobInfo?.codeOwners.slice(0, 5) || [];
    },
    collapsedCodeOwners() {
      return this.blobInfo?.codeOwners.slice(5) || [];
    },
    lastIndexOfCollapsedCodeOwners() {
      return this.collapsedCodeOwners.length - 1;
    },
    toggleText() {
      return this.isCodeOwnersExpanded
        ? __('show less')
        : sprintf(__('%{count} more'), { count: this.collapsedCodeOwners.length });
    },
    hasCodeOwners() {
      return this.filePath && Boolean(this.visibleCodeOwners.length);
    },
    commaSeparateList() {
      return this.visibleCodeOwners.length > 1;
    },
  },
  watch: {
    filePath() {
      this.isFetching = true;
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
    v-if="hasCodeOwners && !isFetching"
    class="well-segment blob-auxiliary-viewer file-owner-content gl-display-flex gl-justify-content-space-between gl-align-items-center"
  >
    <div class="gl-display-flex gl-flex-wrap">
      <div class="gl-display-inline gl-mr-2">
        <gl-icon name="users" data-testid="users-icon" />
        <gl-link
          class="gl-font-weight-bold gl-text-black-normal!"
          :href="codeOwnersPath"
          data-testid="codeowners-file-link"
          >{{ $options.i18n.title }}</gl-link
        >
        <gl-link
          :href="$options.codeOwnersHelpPath"
          target="_blank"
          :title="$options.i18n.about"
          data-testid="codeowners-docs-link"
        >
          <gl-icon name="question-o" data-testid="help-icon" />
        </gl-link>
        :
      </div>
      <div v-for="(owner, index) in visibleCodeOwners" :key="owner.id" data-testid="code-owners">
        <span v-if="commaSeparateList && index > 0" data-testid="comma-separator">, </span>
        <gl-link :href="owner.webPath" target="_blank">
          {{ owner.name }}
        </gl-link>
      </div>

      <template v-if="collapsedCodeOwners.length && isCodeOwnersExpanded">
        <div
          v-for="(owner, index) in collapsedCodeOwners"
          :key="owner.id"
          class="gl-display-inline"
          data-testid="code-owners"
        >
          <span v-if="index !== lastIndexOfCollapsedCodeOwners" data-testid="comma-separator"
            >,
          </span>
          <span v-else data-testid="and-separator" class="gl-ml-2"> {{ $options.i18n.and }} </span>
          <gl-link :href="owner.webPath" target="_blank">
            {{ owner.name }}
          </gl-link>
        </div>
      </template>

      <template v-if="collapsedCodeOwners.length">
        <span v-if="!isCodeOwnersExpanded" class="gl-ml-2"> {{ $options.i18n.and }} </span>
        <gl-button
          class="gl-ml-2"
          variant="link"
          data-testid="collapse-toggle"
          @click="toggleCodeOwners"
        >
          {{ toggleText }}
        </gl-button>
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
