# Investigation

- Read the code path before you make a claim about its behavior. A name, a convention, or a framework default is only a hypothesis.
- Compare each hypothesis with the code of this project. This is most important for the edge branches: an empty result, a missing config, the default path.
- When a problem stops during an investigation, separate what stopped the symptom from what caused it. Give the cause as the answer.
- Read files whole, and batch the reads ({{read_tool}}, {{search_tool}}, one complete script). Do not use a series of small probe commands that each ask for approval.
- For the API of a library at a given version, read its official, versioned docs first. Do not start in a module cache or `node_modules`.
- Read the source when the debug work depends on the implementation.
- When you save a memory after an investigation, save the surprising structural fact (a timing interaction, an undocumented default). Do not save the recipe that fixed this one incident.
- If the system shows the fact in minutes, save nothing.
