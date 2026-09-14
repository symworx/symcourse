{
  "name": "__COURSE_NAME__ Dev Container",
  "build": {
    "dockerfile": "../Containerfile",
    "context": ".."
  },
  "workspaceFolder": "/app",
  "workspaceMount": "source=${localWorkspaceFolder},target=/app,type=bind",
  "runArgs": ["--security-opt=label=disable"],
  "postCreateCommand": "/usr/local/bin/install-learner-agents /app",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/opt/__VENV_NAME__/bin/python"
      }
    }
  }
}
