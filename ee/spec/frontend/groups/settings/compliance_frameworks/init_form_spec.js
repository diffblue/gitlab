import { createWrapper } from '@vue/test-utils';

import CreateForm from 'ee/groups/settings/compliance_frameworks/components/create_form.vue';
import EditForm from 'ee/groups/settings/compliance_frameworks/components/edit_form.vue';
import { createComplianceFrameworksFormApp } from 'ee/groups/settings/compliance_frameworks/init_form';
import { suggestedLabelColors } from './mock_data';

describe('createComplianceFrameworksFormApp', () => {
  let wrapper;
  let el;

  const groupEditPath = 'group-1/edit';
  const groupPath = 'group-1';
  const pipelineConfigurationFullPathEnabled = true;
  const graphqlFieldName = 'field';
  const testId = '1';

  const findFormApp = (form) => wrapper.findComponent(form);

  const setUpDocument = (id = null) => {
    el = document.createElement('div');
    el.setAttribute('data-group-edit-path', groupEditPath);
    el.setAttribute('data-group-path', groupPath);
    el.setAttribute('data-pipeline-configuration-full-path-enabled', 'true');

    if (id) {
      el.setAttribute('data-graphql-field-name', graphqlFieldName);
      el.setAttribute('data-framework-id', id);
    }

    document.body.appendChild(el);

    wrapper = createWrapper(createComplianceFrameworksFormApp(el));
  };

  beforeEach(() => {
    gon.suggested_label_colors = suggestedLabelColors;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    el.remove();
    el = null;
  });

  describe('CreateForm', () => {
    beforeEach(() => {
      setUpDocument();
    });

    it('parses and passes props', () => {
      expect(findFormApp(CreateForm).props()).toStrictEqual({
        groupEditPath,
        groupPath,
        pipelineConfigurationFullPathEnabled,
      });
    });
  });

  describe('EditForm', () => {
    beforeEach(() => {
      setUpDocument(testId);
    });

    it('parses and passes props', () => {
      expect(findFormApp(EditForm).props()).toStrictEqual({
        graphqlFieldName,
        groupEditPath,
        groupPath,
        id: testId,
        pipelineConfigurationFullPathEnabled,
      });
    });
  });
});
