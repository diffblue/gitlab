<script>
import { GlFormGroup, GlFormInput, GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { createAlert } from '~/alert';
import { getGroupPathAvailability } from '~/rest_api';
import { __, s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { slugify, convertUnicodeToAscii } from '~/lib/utils/text_utility';
import { DEFAULT_GROUP_PATH, DEFAULT_PROJECT_PATH } from '../constants';

const DEBOUNCE_TIMEOUT_DURATION = 1000;

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    importGroup: {
      type: Boolean,
      required: true,
    },
    groupPersisted: {
      type: Boolean,
      required: true,
    },
    groupId: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
      required: true,
    },
    projectName: {
      type: String,
      required: true,
    },
    rootUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      projectPath: DEFAULT_PROJECT_PATH,
      currentApiRequestController: null,
      groupPathWithoutSuggestion: null,
    };
  },
  computed: {
    ...mapState(['storeGroupName', 'storeGroupPath']),
    placement() {
      return bp.getBreakpointSize() === 'xs' ? 'bottom' : 'right';
    },
    urlGroupPath() {
      // for persisted group we should not show suggestions but just slugify group name
      return this.groupPersisted && !this.importGroup
        ? this.groupPathWithoutSuggestion
        : this.storeGroupPath;
    },
  },
  mounted() {
    if (this.groupName) {
      this.groupPathWithoutSuggestion = slugify(this.groupName);
      this.onGroupUpdate(this.groupName);
    }

    if (this.projectName) {
      this.onProjectUpdate(this.projectName);
    }
  },
  methods: {
    ...mapActions(['setStoreGroupName', 'setStoreGroupPath']),
    groupInputAttr(name) {
      return `${this.importGroup ? 'import_' : ''}${name}`;
    },
    setSuggestedSlug(slug) {
      if (this.currentApiRequestController !== null) {
        this.currentApiRequestController.abort();
      }

      this.currentApiRequestController = new AbortController();

      // parent ID always undefined because it's a sign up page and a new group
      return getGroupPathAvailability(slug, undefined, {
        signal: this.currentApiRequestController.signal,
      })
        .then(({ data }) => data)
        .then(({ exists, suggests }) => {
          this.currentApiRequestController = null;

          if (exists && suggests.length) {
            const [suggestedSlug] = suggests;
            this.setStoreGroupPath(suggestedSlug);
          } else if (exists && !suggests.length) {
            createAlert({
              message: s__('ProjectsNew|Unable to suggest a path. Please refresh and try again.'),
            });
          }
        })
        .catch((error) => {
          if (axios.isCancel(error)) return;

          createAlert({
            message: s__(
              'ProjectsNew|An error occurred while checking group path. Please refresh and try again.',
            ),
          });
        });
    },
    debouncedOnGroupUpdate: debounce(function debouncedUpdate(slug) {
      this.setSuggestedSlug(slug);
    }, DEBOUNCE_TIMEOUT_DURATION),
    onGroupUpdate(value) {
      const slug = slugify(value);
      this.setStoreGroupName(value);

      if (!slug) return this.setStoreGroupPath(DEFAULT_GROUP_PATH);

      this.setStoreGroupPath(slug);
      return this.debouncedOnGroupUpdate(slug);
    },
    onProjectUpdate(value) {
      this.projectPath = slugify(convertUnicodeToAscii(value)) || DEFAULT_PROJECT_PATH;
    },
  },
  i18n: {
    groupNameLabel: s__('ProjectsNew|Group name'),
    projectNameLabel: s__('ProjectsNew|Project name'),
    tooltipTitle: s__('ProjectsNew|Projects are organized into groups'),
    urlHeader: s__('ProjectsNew|Your project will be created at:'),
    urlFooter: s__('ProjectsNew|You can always change your URL later'),
    urlSlash: __('/'),
  },
};
</script>
<template>
  <div>
    <div class="row">
      <gl-form-group
        class="group-name-holder col-sm-12"
        :label="$options.i18n.groupNameLabel"
        label-for="group_name"
      >
        <gl-form-input
          v-if="groupPersisted && !importGroup"
          id="group_name"
          disabled
          name="group[name]"
          data-testid="persisted-group-name"
          :value="groupName"
        />

        <gl-form-input
          v-if="groupPersisted && !importGroup"
          id="group_id"
          hidden
          name="group[id]"
          autocomplete="off"
          :value="groupId"
        />

        <gl-form-input
          v-if="!groupPersisted || importGroup"
          :id="groupInputAttr('group_name')"
          v-gl-tooltip="{ placement, title: $options.i18n.tooltipTitle }"
          required
          class="js-group-name-field"
          name="group[name]"
          data-testid="group-name"
          data-placement="right"
          data-show="true"
          :data-qa-selector="groupInputAttr('group_name_field')"
          :value="groupName || storeGroupName"
          @update="onGroupUpdate"
        />

        <gl-form-input
          v-if="!groupPersisted || importGroup"
          :id="groupInputAttr('group_path')"
          hidden
          name="group[path]"
          autocomplete="off"
          :value="storeGroupPath"
        />
      </gl-form-group>
    </div>
    <div v-if="!importGroup" id="blank-project-name" class="row">
      <gl-form-group
        class="project-name col-sm-12"
        :label="$options.i18n.projectNameLabel"
        label-for="project_name"
      >
        <gl-form-input
          id="blank_project_name"
          required
          name="project[name]"
          data-testid="project-name"
          data-track-label="blank_project"
          data-track-action="activate_form_input"
          data-track-property="project_name"
          data-track-value=""
          data-qa-selector="project_name_field"
          :value="projectName"
          @update="onProjectUpdate"
        />
      </gl-form-group>
    </div>

    <p class="form-text gl-text-center">{{ $options.i18n.urlHeader }}</p>

    <p class="form-text gl-text-center monospace gl-overflow-wrap-break">
      {{ rootUrl }}<span data-testid="url-group-path">{{ urlGroupPath }}</span
      ><span>{{ $options.i18n.urlSlash }}</span
      ><span data-testid="url-project-path">{{ projectPath }}</span>
    </p>

    <p class="form-text text-muted gl-text-center gl-mb-5!">
      {{ $options.i18n.urlFooter }}
    </p>
  </div>
</template>
