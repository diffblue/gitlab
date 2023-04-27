<script>
import { GlPopover, GlLink, GlAvatar, GlButton, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import { filterState, I18N_LEGACY_REFERENCE_DEPRECATION_NOTE_POPOVER } from '../constants';
import RequirementMeta from '../mixins/requirement_meta';
import RequirementStatusBadge from './requirement_status_badge.vue';

export default {
  i18n: {
    archiveLabel: __('Archive'),
    editLabel: __('Edit'),
    legacyReferencePopoverText: I18N_LEGACY_REFERENCE_DEPRECATION_NOTE_POPOVER,
  },
  components: {
    GlPopover,
    GlLink,
    GlAvatar,
    GlButton,
    RequirementStatusBadge,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [RequirementMeta, timeagoMixin],
  props: {
    requirement: {
      type: Object,
      required: true,
      validator: (value) =>
        [
          'iid',
          'state',
          'userPermissions',
          'title',
          'createdAt',
          'updatedAt',
          'author',
          'testReports',
          'workItemIid',
        ].every((prop) => value[prop]),
    },
    stateChangeRequestActive: {
      type: Boolean,
      required: false,
      default: false,
    },
    active: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showIssuableMetaActions() {
      return Boolean(this.canUpdate || this.canArchive || this.testReport);
    },
    legacyReferencePopoverId() {
      return `legacy-reference-${this.requirement.iid}`;
    },
  },
  methods: {
    /**
     * This is needed as an independent method since
     * when user changes current page, `$refs.authorLink`
     * will be null until next page results are loaded & rendered.
     */
    getAuthorPopoverTarget() {
      if (this.$refs.authorLink) {
        return this.$refs.authorLink.$el;
      }
      return '';
    },
    handleArchiveClick() {
      this.$emit('archiveClick', {
        iid: this.requirement.iid,
        state: filterState.archived,
      });
    },
    handleReopenClick() {
      this.$emit('reopenClick', {
        iid: this.requirement.iid,
        state: filterState.opened,
      });
    },
  },
};
</script>

<template>
  <li
    class="issue requirement gl-cursor-pointer"
    :class="{ 'disabled-content': stateChangeRequestActive, 'gl-bg-blue-50': active }"
    @click="$emit('show-click', requirement)"
  >
    <div class="issuable-info-container">
      <span
        class="issuable-reference gl-text-gray-600 gl-display-none gl-sm-display-block! gl-mr-3"
        >{{ reference }}</span
      >
      <div class="issuable-main-info">
        <span class="issuable-reference gl-text-gray-600 gl-display-block gl-sm-display-none!">{{
          reference
        }}</span>
        <div class="issue-title title">
          <span class="issue-title-text">{{ requirement.title }}</span>
        </div>
        <div class="issuable-info gl-display-none gl-sm-display-inline-block!">
          <span :id="legacyReferencePopoverId" class="issuable-legacy-reference">{{
            legacyReference
          }}</span>
          <span class="issuable-authored">
            <span v-gl-tooltip:tooltipcontainer.bottom :title="tooltipTitle(requirement.createdAt)"
              >&middot; {{ createdAtFormatted }}</span
            >
            {{ __('by') }}
            <gl-link ref="authorLink" class="author-link js-user-link" :href="author.webUrl">
              <span class="author">{{ author.name }}</span>
            </gl-link>
          </span>
          <span
            v-gl-tooltip:tooltipcontainer.bottom
            :title="tooltipTitle(requirement.updatedAt)"
            class="issuable-updated-at"
            >&middot; {{ updatedAtFormatted }}</span
          >
        </div>
        <requirement-status-badge
          v-if="testReport"
          :test-report="testReport"
          :last-test-report-manually-created="requirement.lastTestReportManuallyCreated"
          class="gl-display-block gl-sm-display-none!"
        />
      </div>
      <div class="d-flex">
        <ul
          v-if="showIssuableMetaActions"
          class="controls gl-flex-direction-column gl-sm-flex-direction-row!"
        >
          <requirement-status-badge
            v-if="testReport"
            :test-report="testReport"
            :last-test-report-manually-created="requirement.lastTestReportManuallyCreated"
            element-type="li"
            class="gl-display-none gl-sm-display-block!"
          />
          <li v-if="canUpdate && !isArchived" class="requirement-edit gl-sm-display-block!">
            <gl-button
              v-gl-tooltip
              icon="pencil"
              :title="$options.i18n.editLabel"
              :aria-label="$options.i18n.editLabel"
              @click="$emit('edit-click', requirement)"
            />
          </li>
          <li v-if="canArchive && !isArchived" class="requirement-archive gl-sm-display-block!">
            <gl-button
              v-if="!stateChangeRequestActive"
              v-gl-tooltip
              icon="archive"
              :loading="stateChangeRequestActive"
              :title="$options.i18n.archiveLabel"
              :aria-label="$options.i18n.archiveLabel"
              @click.stop="handleArchiveClick"
            />
          </li>
          <li v-if="canArchive && isArchived" class="requirement-reopen gl-sm-display-block!">
            <gl-button :loading="stateChangeRequestActive" @click="handleReopenClick">{{
              __('Reopen')
            }}</gl-button>
          </li>
        </ul>
      </div>
    </div>
    <gl-popover :target="getAuthorPopoverTarget()" placement="top">
      <div class="gl-line-height-normal gl-display-flex">
        <div class="gl-p-2 gl-flex-shrink-1">
          <gl-avatar :entity-name="author.name" :alt="author.name" :src="author.avatarUrl" />
        </div>
        <div class="gl-p-2 gl-w-full">
          <h5 class="gl-m-0">{{ author.name }}</h5>
          <div class="gl-text-gray-500 gl-mb-3">@{{ author.username }}</div>
        </div>
      </div>
    </gl-popover>
    <gl-popover
      data-testid="legacy-reference-popover"
      :target="legacyReferencePopoverId"
      placement="top"
    >
      <span class="gl-line-height-20">
        <gl-sprintf :message="$options.i18n.legacyReferencePopoverText">
          <template #id>{{ reference }}</template>
          <template #link="{ content }">
            <gl-link
              class="gl-font-size-inherit"
              :href="$options.legacyReferenceDeprecationUrl"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </span>
    </gl-popover>
  </li>
</template>
