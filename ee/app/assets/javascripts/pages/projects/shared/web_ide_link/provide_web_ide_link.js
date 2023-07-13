/**
 * Inspects an object and extracts properties
 * that are relevant to the web_ide_link.vue
 * component. In the case of the EE version,
 * it looks for the newWorkspacePath property.
 *
 * @returns An object with properties that are
 * relevant to the web_ide_link.vue component.
 */
export const provideWebIdeLink = ({ newWorkspacePath } = {}) => ({
  newWorkspacePath,
});
