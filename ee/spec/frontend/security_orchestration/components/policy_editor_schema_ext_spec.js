import { setDiagnosticsOptions } from 'monaco-yaml';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { PolicySchemaExtension } from 'ee/security_orchestration/components/policy_editor_schema_ext';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/security_orchestration/components/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import SourceEditor from '~/editor/source_editor';
import { getSinglePolicySchema } from 'ee/security_orchestration/components/utils';

jest.mock('ee/security_orchestration/components/utils', () => ({
  getSchemaUrl: jest.fn().mockReturnValue('mock/schema.json'),
  getSinglePolicySchema: jest.fn().mockResolvedValue({ test: 'value' }),
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
    describe('register validations options with monaco for yaml language', () => {
      const mockNamespacePath = 'namespace1';

      it('registers the schema', async () => {
        await instance.registerSecurityPolicySchema({
          namespacePath: mockNamespacePath,
          namespaceType: NAMESPACE_TYPES.PROJECT,
          policyType: POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter,
        });

        expect(setDiagnosticsOptions).toHaveBeenCalledTimes(1);
        expect(getSinglePolicySchema).toHaveBeenCalledTimes(1);
      });
    });
  });
});
