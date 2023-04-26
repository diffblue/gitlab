import $ from 'jquery';
import Vue from 'vue';
import GlFieldErrors from '~/gl_field_errors';
import { parseBoolean } from '~/lib/utils/common_utils';
import { bindHowToImport } from '~/projects/project_new';
import GroupProjectFields from './components/group_project_fields.vue';
import createStore from './store';

const importButtonsSubmit = () => {
  const buttons = document.querySelectorAll('.js-import-project-buttons a');
  const form = document.querySelector('.js-import-project-form');
  const submit = form.querySelector('input[type="submit"]');
  const importUrlField = form.querySelector('.js-import-url');

  const clickHandler = (e) => {
    e.preventDefault();
    importUrlField.value = e.currentTarget.getAttribute('href');
    submit.click();
  };

  buttons.forEach((button) => button.addEventListener('click', clickHandler));
};

const setAutofocus = () => {
  const setInputfocus = () => {
    document
      .querySelector('.js-group-project-tab-contents .tab-pane.active .js-group-name-field')
      ?.focus();
  };

  setInputfocus();

  $('.js-group-project-tabs').on('shown.bs.tab', setInputfocus);
};

const mountGroupProjectFields = (el, store) => {
  if (!el) {
    return null;
  }

  const { importGroup, groupPersisted, groupId, groupName, projectName, rootUrl } = el.dataset;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(GroupProjectFields, {
        props: {
          importGroup: parseBoolean(importGroup),
          groupPersisted: parseBoolean(groupPersisted),
          groupId: groupId || '',
          groupName: groupName || '',
          projectName: projectName || '',
          rootUrl,
        },
      });
    },
  });
};

const mountCreateImportGroupProjectFields = () => {
  const store = createStore();

  [...document.querySelectorAll('.js-create-import-group-project-fields')].map((el) =>
    mountGroupProjectFields(el, store),
  );

  // Since we replaced form inputs, we need to re-initialize the field errors handler
  return new GlFieldErrors(document.querySelectorAll('.gl-show-field-errors'));
};

export default () => {
  importButtonsSubmit();
  bindHowToImport();
  setAutofocus();
  mountCreateImportGroupProjectFields();
};
