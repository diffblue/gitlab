import { languages } from 'monaco-editor';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { PolicySchemaExtension } from 'ee/security_orchestration/components/policy_editor_schema_ext';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import SourceEditor from '~/editor/source_editor';
import { getSingleScanExecutionPolicySchema } from 'ee/security_orchestration/components/utils';

jest.mock('ee/security_orchestration/components/utils', () => ({
  getSchemaUrl: jest.fn().mockReturnValue('mock/schema.json'),
  getSingleScanExecutionPolicySchema: jest.fn().mockResolvedValue({ test: 'value' }),
}));

describe('PolicySchemaExtension', () => {
  let editor;
  let instance;
  let editorEl;

  const createMockEditor = ({ blobPath = 'policy.yml' } = {}) => {
    setHTMLFixture('<div id="editor"></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
    instance = editor.createInstance({
      el: editorEl,
      blobPath,
      blobContent: '',
    });
    instance.use({ definition: PolicySchemaExtension });
  };

  beforeEach(() => {
    createMockEditor();
  });

  afterEach(() => {
    instance.dispose();

    editorEl.remove();
    resetHTMLFixture();
  });

  describe('registerSecurityPolicySchema', () => {
    beforeEach(() => {
      jest.spyOn(languages.yaml.yamlDefaults, 'setDiagnosticsOptions');
    });

    describe('register validations options with monaco for yaml language', () => {
      const mockNamespacePath = 'namespace1';

      it.each`
        title         | policyType                                                  | namespaceType              | itRegistersASchema | schemaFunction
        ${'does'}     | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter} | ${NAMESPACE_TYPES.PROJECT} | ${true}            | ${getSingleScanExecutionPolicySchema}
        ${'does'}     | ${POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter} | ${NAMESPACE_TYPES.GROUP}   | ${true}            | ${getSingleScanExecutionPolicySchema}
        ${'does not'} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter}    | ${NAMESPACE_TYPES.PROJECT} | ${false}           | ${() => ({})}
        ${'does not'} | ${POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter}    | ${NAMESPACE_TYPES.GROUP}   | ${false}           | ${() => ({})}
      `(
        '$title register the schema for $namespaceType $policyType policy',
        async ({ policyType, namespaceType, itRegistersASchema, schemaFunction }) => {
          await instance.registerSecurityPolicySchema({
            namespacePath: mockNamespacePath,
            namespaceType,
            policyType,
          });

          if (itRegistersASchema) {
            expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledTimes(1);
            expect(schemaFunction).toHaveBeenCalledTimes(1);
          } else {
            expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).not.toHaveBeenCalled();
          }
        },
      );
    });
  });
});
