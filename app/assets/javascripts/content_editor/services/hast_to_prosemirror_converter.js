import { Mark } from 'prosemirror-model';
import { visitParents } from 'unist-util-visit-parents';
import { toString } from 'hast-util-to-string';
import { isFunction } from 'lodash';

/**
 * Merges two ProseMirror text nodes if both text nodes
 * have the same set of marks.
 *
 * ProseMirror Node: https://prosemirror.net/docs/ref/#model.Node
 *
 * @param {ProseMirror.Node} a first ProseMirror node
 * @param {ProseMirror.Node} b second ProseMirror node
 * @returns {model.Node} A new text node that results from combining
 * the text of the two text node parameters or null.
 */
function maybeMerge(a, b) {
  if (a && a.isText && b && b.isText && Mark.sameSet(a.marks, b.marks)) {
    return a.withText(a.text + b.text);
  }

  return null;
}

/**
 * Creates an object that contains sourcemap position information
 * included in a Hast Abstract Syntax Tree. The Content
 * Editor uses the sourcemap information to restore the
 * original source of a node when the user doesn’t change it.
 *
 * Unist syntax tree documentation: https://github.com/syntax-tree/unist
 * Hast node documentation: https://github.com/syntax-tree/hast
 *
 * @param {HastNode} hastNode A Hast node
 * @param {String} source Markdown source file
 *
 * @returns It returns an object with the following attributes:
 *
 * - sourceMapKey: A string that uniquely identifies what is
 * the position of the hast node in the Markdown source file.
 * - sourceMarkdown: A node’s original Markdown source extrated
 * from the Markdown source file.
 */
function createSourceMapAttributes(hastNode, source) {
  const { position } = hastNode;

  return {
    sourceMapKey: `${position.start.offset}:${position.end.offset}`,
    sourceMarkdown: source.substring(position.start.offset, position.end.offset),
  };
}

/**
 * Compute ProseMirror node’s attributes from a Hast node.
 * By default, this function includes sourcemap position
 * information in the object returned.
 *
 * Other attributes are retrieved by invoking a getAttrs
 * function provided by the ProseMirror node factory spec.
 *
 * Hast node documentation: https://github.com/syntax-tree/hast
 *
 * @param {*} proseMirrorNodeSpec ProseMirror node spec object
 * @param {HastNode} hastNode A hast node
 * @param {Array<HastNode>} hastParents All the ancestors of the hastNode
 * @param {String} source Markdown source file’s content
 *
 * @returns An object that contains a ProseMirror node’s attributes
 */
function getAttrs(proseMirrorNodeSpec, hastNode, hastParents, source) {
  const { getAttrs: specGetAttrs } = proseMirrorNodeSpec;

  return {
    ...createSourceMapAttributes(hastNode, source),
    ...(isFunction(specGetAttrs) ? specGetAttrs(hastNode, hastParents, source) : {}),
  };
}

/**
 * Keeps track of the Hast -> ProseMirror conversion process.
 *
 * Node state
 *
 * When the `openNode` method is invoked, it adds the node to a stack
 * data structure. When the `closeNode` method is invoked, it removes the
 * last element from the Stack, creates a ProseMirror node, and adds that
 * ProseMirror node to the previous node in the Stack.
 *
 * For example, given a Hast tree with three levels of nodes:
 *
 * - blockquote
 *   - paragraph
 *     - text
 *
 * This class will store this tree in the Stack in the following way:
 *
 * 3. text
 * 2. paragraph
 * 1. blockquote
 *
 * Calling `closeNode` will fold the text node into paragraph. A 2nd
 * call to this method will fold "paragraph" into "blockquote".
 *
 * Mark state
 *
 * When the `openMark` method is invoked, this class adds the Mark to a `MarkSet`
 * object. When a text node is added, it assigns all the opened marks to that text
 * node and cleans the marks. It takes care of merging text nodes with the same
 * set of marks as well.
 */
class HastToProseMirrorConverterState {
  constructor() {
    this.stack = [];
    this.marks = Mark.none;
  }

  push(node) {
    this.stack.push(node);
  }

  pop() {
    return this.stack.pop();
  }

  get top() {
    return this.stack[this.stack.length - 1];
  }

  get empty() {
    return this.stack.length === 0;
  }

  addText(schema, text) {
    if (!text) return;
    const nodes = this.top.content;
    const last = nodes[nodes.length - 1];
    const node = schema.text(text, this.marks);
    const merged = maybeMerge(last, node);

    if (last && merged) {
      nodes[nodes.length - 1] = merged;
    } else {
      nodes.push(node);
    }

    this.clearMarks();
  }

  openMark(markType, attrs) {
    this.marks = markType.create(attrs).addToSet(this.marks);
  }

  clearMarks() {
    this.marks = Mark.none;
  }

  addNode(type, attrs, content) {
    const node = type.createAndFill(attrs, content, this.marks);
    if (!node) return null;

    if (!this.empty) {
      this.top.content.push(node);
    }
    return node;
  }

  openNode(type, hastNode, attrs, factorySpec) {
    this.push({ type, attrs, content: [], token: hastNode, factorySpec });
  }

  closeUntilParent(parent) {
    while (parent !== this.top?.token) {
      this.closeNode();
    }
  }

  closeNode() {
    if (this.marks.length) this.marks = Mark.none;
    const info = this.pop();
    return this.addNode(info.type, info.attrs, info.content);
  }
}

/**
 * Create ProseMirror node factories based on one or more factory specifications.
 *
 * Note: Read the public API documentation of this module for instructions about how
 * to define these specifications.
 *
 * @param {model.ProseMirrorSchema} schema A ProseMirror schema used to create the
 * ProseMirror nodes and marks.
 * @param {Object} proseMirrorFactorySpecs ProseMirror nodes factory specifications.
 * @param {String} source Markdown source file’s content
 *
 * @returns An object that contains ProseMirror node factories
 */
const createProseMirrorNodeFactories = (schema, proseMirrorFactorySpecs, source) => {
  const handlers = {};

  Object.keys(proseMirrorFactorySpecs).forEach((hastNodeTagName) => {
    const factorySpec = proseMirrorFactorySpecs[hastNodeTagName];

    if (factorySpec.block) {
      handlers[hastNodeTagName] = (state, hastNode, parent, ancestors) => {
        const nodeType = schema.nodeType(
          isFunction(factorySpec.block)
            ? factorySpec.block(hastNode, parent, ancestors)
            : factorySpec.block,
        );

        state.closeUntilParent(parent);
        state.openNode(
          nodeType,
          hastNode,
          getAttrs(factorySpec, hastNode, parent, source),
          factorySpec,
        );
      };
    } else if (factorySpec.node) {
      const nodeType = schema.nodeType(factorySpec.node);
      handlers[hastNodeTagName] = (state, hastNode, parent) => {
        state.closeUntilParent(parent);

        if (factorySpec.inlineContent === true) {
          state.openNode(
            nodeType,
            hastNode,
            getAttrs(factorySpec, hastNode, parent, source),
            factorySpec,
          );
          state.addText(schema, toString(hastNode));
        } else {
          state.addNode(nodeType, getAttrs(factorySpec, hastNode, parent, source));
        }
      };
    } else if (factorySpec.mark) {
      const markType = schema.marks[factorySpec.mark];
      handlers[hastNodeTagName] = (state, hastNode, parent) => {
        state.openMark(markType, getAttrs(factorySpec, hastNode, parent, source));

        if (factorySpec.inlineContent) {
          state.addText(schema, hastNode.value);
        }
      };
    } else {
      throw new RangeError(`Unrecognized node factory spec ${JSON.stringify(factorySpec)}`);
    }
  });

  handlers.text = (state, hastNode) => {
    const { factorySpec } = state.top;

    if (/^\s+$/.test(hastNode.value)) {
      return;
    }

    if (factorySpec.wrapTextInParagraph === true) {
      state.openNode(schema.nodeType('paragraph'));
      state.addText(schema, hastNode.value.trim());
      state.closeNode();
    } else {
      state.addText(schema, hastNode.value);
    }
  };

  handlers.softbreak = handlers.softbreak || ((state) => state.addText(schema, '\n'));

  return handlers;
};

/**
 * Converts a Hast Abstract Syntax Tree to a ProseMirror document based on a series
 * of specifications that describe how to map all the nodes of the former to ProseMirror
 * nodes or marks.
 *
 * This converter will trigger an error if it doesn’t find a specification for a Hast node.
 * The specification object describes how to map a Hast node to a ProseMirror node or mark. It
 * should have the following shape:
 *
 *  {
 *    [hastNode.tagName]:
 *  }
 *
 *  Where each property in the object represents a HAST node with a given tag name, for example:
 *
 *  {
 *    h1: {},
 *    h2: {},
 *    table: {},
 *    strong: {},
 *    // etc
 *  }
 *
 * Each HAST node should map to a ProseMirror node. A ProseMirror node can have one of the following
 * types:
 *
 * 1. A "block" type which contains one or more children.
 * 2. A "node" or leaf type doesn’t contain any children, but it can have inline, unstructured content.
 * 3. A "mark" decorates text nodes.
 *
 * Use the following syntax to indicate how to map a HAST node to a ProseMirror node:
 *
 * {
 *   [hastNode.tagName]: {
 *     [block|node|mark]: [ProseMirror.Node.name],
 *   }
 * }
 *
 * For example:
 *
 * {
 *    h1: {
 *      block: 'heading',
 *    },
 *    h2: {
 *      block: 'heading',
 *    },
 *    img: {
 *      node: 'image',
 *    },
 *    strong: {
 *      mark: 'bold',
 *    }
 * }
 *
 * You can compute a ProseMirror’s node or mark name based on the HAST node
 * by passing a function instead of a String. The converter invokes the function
 * and provides a HAST node object:
 *
 * {
 *    list: {
 *      block: (hastNode) => {
 *        let type = 'bulletList';

 *        if (hastNode.children.some(isTaskItem)) {
 *         type = 'taskList';
 *        } else if (hastNode.ordered) {
 *         type = 'orderedList';
 *        }

 *        return type;
 *     }
 *   }
 * }
 *
 * You can also provide a `getAttrs` function to compute a ProseMirror node
 * or mark attributes. The converter will invoke `getAttrs` with the following
 * parameters:
 *
 * 1. hastNode: The hast node
 * 2. hasParents: All the hast node’s ancestors up to the root node
 * 3. source: Markdown source file’s content
 *
 * Unist syntax tree documentation: https://github.com/syntax-tree/unist
 * Hast tree documentation: https://github.com/syntax-tree/hast
 * ProseMirror document documentation: https://prosemirror.net/docs/ref/#model.Document_Structure
 *
 * @param {model.Document_Schema} params.schema A ProseMirror schema that specifies the shape
 * of the ProseMirror document.
 * @param {Object} params.factorySpec A factory specification as described above
 * @param {Hast} params.tree https://github.com/syntax-tree/hast
 * @param {String} params.source Markdown source from which the MDast tree was generated
 *
 * @returns A ProseMirror document
 */
export const createProseMirrorDocFromMdastTree = ({ schema, factorySpecs, tree, source }) => {
  const proseMirrorNodeFactories = createProseMirrorNodeFactories(schema, factorySpecs, source);
  const state = new HastToProseMirrorConverterState();

  state.push({ type: schema.topNodeType, content: [], token: tree });

  visitParents(tree, (hastNode, ancestors) => {
    if (ancestors.length === 0) {
      return true;
    }

    const parent = ancestors[ancestors.length - 1];
    const skipChildren = factorySpecs[hastNode.tagName]?.skipChildren;

    const handler = proseMirrorNodeFactories[hastNode.tagName || hastNode.type];

    if (!handler) {
      throw new Error(
        `Hast node of type "${
          hastNode.tagName || hastNode.type
        }" not supported by this converter. Please, provide an specification.`,
      );
    }

    handler(state, hastNode, parent, ancestors);

    return skipChildren === true ? 'skip' : true;
  });

  let doc;

  do {
    doc = state.closeNode();
  } while (!state.empty);

  return doc;
};
