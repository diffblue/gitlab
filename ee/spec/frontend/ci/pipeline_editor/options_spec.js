import { editorDatasetOptions, expectedInjectValues } from 'jest/ci/pipeline_editor/mock_data';
import { createAppOptions } from 'ee/ci/pipeline_editor/options';

describe('createAppOptions', () => {
  let el;

  const mergedOptions = {
    ...editorDatasetOptions,
    canViewNamespaceCatalog: 'true',
    ciCatalogPath: '/ci/catalog/resources',
  };

  const createElement = () => {
    el = document.createElement('div');

    document.body.appendChild(el);
    Object.entries(mergedOptions).forEach(([k, v]) => {
      el.dataset[k] = v;
    });
  };

  afterEach(() => {
    el = null;
  });

  it("extracts the properties from the element's dataset", () => {
    createElement();
    const options = createAppOptions(el);
    Object.entries(expectedInjectValues).forEach(([key, value]) => {
      expect(options.provide).toMatchObject({ [key]: value });
    });
  });
});
