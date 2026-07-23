const descriptions: Record<string, string> = {
  invalid: "Do not use.",
  question: "Ask the user a question.",
  bash: "Run a shell command in the project directory.",
  read: "Read a file by path, optionally selecting lines.",
  glob: "Find files by glob pattern.",
  grep: "Search file contents by regular expression.",
  edit: "Replace exact text in a file.",
  write: "Create or overwrite a file.",
  apply_patch: "Apply a patch to files.",
  task: "Delegate work to a subagent; use task_id to resume.",
  webfetch: "Fetch a URL and return its content.",
  websearch: "Search the public web.",
  todowrite: "Replace the session task list.",
  skill: "Load a named skill's instructions.",
  lsp: "Query the project's language server.",
  plan_exit: "Finish planning and request approval to proceed.",
  web_search: "Search the web through local SearXNG.",
  extract_pdf: "Extract text from a local or remote PDF.",
};

export const CompactToolDescriptions = async () => ({
  "tool.definition": async (
    input: { toolID: string },
    output: { description: string },
  ) => {
    const description = descriptions[input.toolID];
    if (description) output.description = description;
  },
});
