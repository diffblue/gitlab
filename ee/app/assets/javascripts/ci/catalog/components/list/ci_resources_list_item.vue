<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlIcon,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';

export default {
  i18n: {
    releasedMessage: s__('CiCatalog|Released %{timeAgo} by %{author}'),
  },
  components: {
    GlAvatar,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    resource: {
      type: Object,
      required: true,
    },
  },
  computed: {
    authorName() {
      return this.lastUpdate.user.name;
    },
    authorProfileUrl() {
      return this.lastUpdate.user.webUrl;
    },
    entityId() {
      return getIdFromGraphQLId(this.resource.id);
    },
    hasFavorites() {
      return this.resource.statistics?.favorites;
    },
    hasForks() {
      return this.resource.statistics?.forks;
    },
    formattedDate() {
      return formatDate(this.lastUpdate?.time);
    },
    formattedVersion() {
      return `v${this.resource.latestVersion}`;
    },
    lastUpdate() {
      return this.resource.lastUpdate;
    },
    releasedAt() {
      return getTimeago().format(this.lastUpdate?.time);
    },
    resourcePath() {
      return `${this.resource.namespace} / ${this.resource.group} / `;
    },
  },
};
</script>
<template>
  <li
    class="gl-display-flex gl-display-flex-wrap gl-border-b-1 gl-border-gray-100 gl-border-b-solid gl-text-gray-500 gl-py-3"
  >
    <gl-avatar-link :href="resource.webPath">
      <gl-avatar
        :entity-id="entityId"
        :entity-name="resource.icon"
        :size="48"
        shape="rect"
        class="gl-mr-4"
      />
    </gl-avatar-link>
    <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1">
      <div class="gl-display-flex gl-flex-wrap gl-flex-grow-1 gl-gap-2">
        <gl-button variant="link" :href="resource.webPath" class="gl-text-gray-900! gl-mr-1">
          {{ resourcePath }} <b> {{ resource.name }}</b>
        </gl-button>
        <div class="gl-display-flex gl-flex-grow-1 gl-md-justify-content-space-between">
          <gl-badge size="sm">{{ formattedVersion }}</gl-badge>
          <span class="gl-display-flex gl-align-items-center gl-ml-5">
            <span v-if="hasFavorites" class="gl--flex-center" data-testid="stats-favorites">
              <gl-icon name="star" :size="14" class="gl-mr-1" />
              <span class="gl-mr-3">{{ resource.statistics.favorites }}</span>
            </span>
            <span v-if="hasForks" class="gl--flex-center" data-testid="stats-forks">
              <gl-icon name="fork" :size="14" class="gl-mr-1" />
              <span>{{ resource.statistics.forks }}</span>
            </span>
          </span>
        </div>
      </div>
      <div class="gl-display-flex gl-sm-flex-direction-column gl-justify-content-space-between">
        <span class="gl-display-flex gl-flex-basis-two-thirds">{{ resource.description }}</span>
        <div class="gl-display-flex gl-justify-content-end">
          <span>
            <gl-sprintf :message="$options.i18n.releasedMessage">
              <template #timeAgo>
                <span v-gl-tooltip.bottom :title="formattedDate">
                  {{ releasedAt }}
                </span>
              </template>
              <template #author>
                <gl-link :href="authorProfileUrl">
                  <span>{{ authorName }}</span>
                </gl-link>
              </template>
            </gl-sprintf>
          </span>
        </div>
      </div>
    </div>
  </li>
</template>
