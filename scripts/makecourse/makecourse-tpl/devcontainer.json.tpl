{
  "name": "__COURSE_NAME__ Dev Container",
  "build": {
    "dockerfile": "../container/Containerfile",
    "context": ".."
  },
  "workspaceFolder": "/app",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  }
}
