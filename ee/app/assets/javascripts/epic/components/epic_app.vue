<script>
import { mapState } from 'vuex';
import initRelatedItemsTree from 'ee/related_items_tree/related_items_tree_bundle';
import IssuableBody from '~/issues/show/components/app.vue';
import { PathIdSeparator } from '~/related_issues/constants';
import SidebarContext from '../sidebar_context';
import EpicHeader from './epic_header.vue';
import EpicHeaderActions from './epic_header_actions.vue';
import EpicSidebar from './epic_sidebar.vue';

export default {
  PathIdSeparator,
  components: {
    IssuableBody,
    EpicHeader,
    EpicHeaderActions,
    EpicSidebar,
  },
  computed: {
    ...mapState([
      'author',
      'created',
      'endpoint',
      'updateEndpoint',
      'groupPath',
      'markdownPreviewPath',
      'markdownDocsPath',
      'canUpdate',
      'canDestroy',
      'initialTitleHtml',
      'initialTitleText',
      'initialDescriptionHtml',
      'initialDescriptionText',
      'lockVersion',
      'state',
      'confidential',
    ]),
    formattedAuthor() {
      const { url, username } = this.author;
      return {
        ...this.author,
        username: username.startsWith('@') ? username.substring(1) : username,
        webUrl: url,
      };
    },
  },
  mounted() {
    new SidebarContext(); // eslint-disable-line no-new
    initRelatedItemsTree();
  },
};
</script>

<template>
  <div class="epic-page-container">
    <div
      class="issuable-details detail-page-description content-block gl-pt-3 gl-pb-0 gl-border-none"
    >
      <issuable-body
        :author="formattedAuthor"
        :created-at="created"
        :endpoint="endpoint"
        :update-endpoint="updateEndpoint"
        :project-path="groupPath"
        :project-id="0"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :can-update="canUpdate"
        :can-destroy="canDestroy"
        :show-delete-button="canDestroy"
        :initial-title-html="initialTitleHtml"
        :initial-title-text="initialTitleText"
        :lock-version="lockVersion"
        :initial-description-html="initialDescriptionHtml"
        :initial-description-text="initialDescriptionText"
        :issuable-status="state"
        :is-confidential="confidential"
        enable-autocomplete
        project-namespace
        issuable-ref
        issuable-type="epic"
      >
        <template #actions>
          <epic-header-actions />
        </template>
        <template #header>
          <epic-header :formatted-author="formattedAuthor" />
        </template>
      </issuable-body>
    </div>
    <epic-sidebar />
  </div>
</template>
