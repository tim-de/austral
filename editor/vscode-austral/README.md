# austral-vscode

VS Code support for the austral programming language.

## Installing

To install austral-vscode first install the VSCode extension manager with

```sh
npm install --global @vscode/vsce
```

Then package the extension with

```sh
# NOTE: working directory must be `editor/vscode-austral`
vsce package
```

This will generate a package file called `austral-$VERSION.vsix`, which can be installed with

```sh
code --install-extension austral-$VERSION.vsix
```

## Debugging

To start a debugging session open this folder in VSCode and press f5, or start debugging from the Run and Debug Menu.
Starting the debugger will open a child VSCode instance with the extension loaded.

To inspect the textmate scopes assigned run the VSCode command "Developer: Inspect Editor Tokens and Scopes" (`editor.action.inspectTMScopes`).

## Features

- Context-aware syntax highlighting.

## Release Notes

### 1.0.0

- Initial release.
- Syntax highlighting.