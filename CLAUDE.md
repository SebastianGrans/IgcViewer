# Instructions for AI agents

- If the user is just asking a question, don't start fixing the problem. Only answer the question.

- If you modify *.qml files, remember to run `make qmllint` to check for syntax errors.
- If you modify *.py files, remember to run `make check` or `make lint` to check for syntax errors
  and style issues.
    - You can also run `make lintall` to check both Python and QML files.