import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import eventHub from '~/projects/new/event_hub';
import projectNew from '~/projects/project_new';

const INSTANCE_TAB_CONTENT_SELECTOR = '.js-custom-instance-project-templates-tab-content';
const GROUP_TAB_CONTENT_SELECTOR = '.js-custom-group-project-templates-tab-content';

const bindEvents = () => {
  const $newProjectForm = $('#new_project');
  const $useCustomTemplateBtn = $('.custom-template-button > input');
  const $projectFieldsForm = $('.project-fields-form');
  const $selectedIcon = $('.selected-icon');
  const $selectedTemplateText = $('.selected-template');
  const $templateProjectNameInput = $('#template-project-name #project_path');
  const $changeTemplateBtn = $('.change-template');
  const $projectTemplateButtons = $('.project-templates-buttons');
  const $projectFieldsFormInput = $('.project-fields-form input#project_use_custom_template');
  const $subgroupWithTemplatesIdInput = $('.js-project-group-with-project-templates-id');
  const $namespaceSelect = $projectFieldsForm.find('.js-select-namespace');
  const $pagination = $('.gl-pagination');
  let hasUserDefinedProjectName = false;

  if ($newProjectForm.length !== 1 || $useCustomTemplateBtn.length === 0) {
    return;
  }

  function enableCustomTemplate() {
    $projectFieldsFormInput.val(true);
  }

  function disableCustomTemplate() {
    $projectFieldsFormInput.val(false);
  }

  function hideNonRootParentPathOptions() {
    const rootParent = `/${
      $namespaceSelect.find('option:selected').data('show-path')?.split('/')[1]
    }`;

    $namespaceSelect
      .find('option')
      .filter(function doesNotMatchParent() {
        return !$(this).data('show-path').includes(rootParent);
      })
      .addClass('hidden');
  }

  function hideOptionlessOptgroups() {
    $namespaceSelect
      .find('optgroup')
      .filter(function noVisibleOptions() {
        return !$(this).find('option:not(.hidden)').length;
      })
      .addClass('hidden');
  }

  function chooseTemplate() {
    const subgroupId = $(this).data('subgroup-id');
    const groupId = $(this).data('parent-group-id');
    const templateName = $(this).data('template-name');

    if (subgroupId) {
      const subgroupFullPath = $(this).data('subgroup-full-path');
      const targetGroupFullPath = $(this).data('target-group-full-path');
      eventHub.$emit(
        'select-template',
        targetGroupFullPath ? groupId : null,
        targetGroupFullPath || subgroupFullPath,
      );

      $subgroupWithTemplatesIdInput.val(subgroupId);
      $namespaceSelect.val(groupId).trigger('change');

      hideNonRootParentPathOptions();

      hideOptionlessOptgroups();
    }

    $projectTemplateButtons.addClass('hidden');
    $projectFieldsForm.addClass('selected');
    $selectedIcon.empty();

    $selectedTemplateText.text(templateName);

    $(this)
      .parents('.template-option')
      .find('.avatar')
      .clone()
      .addClass('d-block')
      .removeClass('s40')
      .appendTo($selectedIcon);

    $templateProjectNameInput.focus();
    enableCustomTemplate();

    const $activeTabProjectName = $('.tab-pane.active #project_name');
    const $activeTabProjectPath = $('.tab-pane.active #project_path');
    $activeTabProjectName.focus();
    $activeTabProjectName.on('keyup', () => {
      projectNew.onProjectNameChangeJq($activeTabProjectName, $activeTabProjectPath);
      hasUserDefinedProjectName = $activeTabProjectName.val().trim().length > 0;
    });
    $activeTabProjectPath.on('keyup', () =>
      projectNew.onProjectPathChangeJq(
        $activeTabProjectName,
        $activeTabProjectPath,
        hasUserDefinedProjectName,
      ),
    );

    $projectFieldsForm.find('.js-select-namespace').first().val(groupId);
  }

  $useCustomTemplateBtn.on('change', chooseTemplate);

  $changeTemplateBtn.on('click', () => {
    $projectTemplateButtons.removeClass('hidden');
    $useCustomTemplateBtn.prop('checked', false);
    $namespaceSelect
      .val($namespaceSelect.find('option[data-options-parent="users"]').val())
      .trigger('change');
    $namespaceSelect.find('option, optgroup').removeClass('hidden');
    disableCustomTemplate();
  });

  $pagination.on('ajax:success', (event) => {
    const $tabContent = $pagination.closest(
      [INSTANCE_TAB_CONTENT_SELECTOR, GROUP_TAB_CONTENT_SELECTOR].join(','),
    );
    const doc = event.detail[0];
    const element = document.adoptNode(doc.body.firstElementChild);

    $tabContent.empty().append(element);
    bindEvents();
  });

  $(document).on('click', '.js-template-group-options', function toggleExpandedClass() {
    $(this).toggleClass('expanded');
  });

  document.querySelector('.js-create-project-button').addEventListener('click', (e) => {
    projectNew.validateGroupNamespaceDropdown(e);
  });
};

export default () => {
  const $navElement = $('.js-custom-instance-project-templates-nav-link');
  const $tabContent = $(INSTANCE_TAB_CONTENT_SELECTOR);
  const $groupNavElement = $('.js-custom-group-project-templates-nav-link');
  const $groupTabContent = $(GROUP_TAB_CONTENT_SELECTOR);
  const fetchHtmlForTabContent = async ($content) => {
    const response = await axios.get($content.data('initialTemplates'));
    // eslint-disable-next-line no-param-reassign
    $content[0].innerHTML = response.data;
    bindEvents();
  };

  $navElement.one('click', () => fetchHtmlForTabContent($tabContent));
  $groupNavElement.one('click', () => fetchHtmlForTabContent($groupTabContent));

  bindEvents();
};
