<div align="center">
  <img src="https://avatars.githubusercontent.com/u/226482377" alt="Logo" width="200">
<h1 align="center"> Siada CLI <br>
</h1>
</div>
Siada CLI is a command-line AI workflow tool that provides intelligent agents for code development and automation tasks.


With Siada CLI you can:
- Fix bugs in large codebases through intelligent analysis and automated solutions.
- Generate new applications and components using specialized frontend and backend agents.
- Automate development workflows through intelligent code generation and testing.
- Execute system commands and interact with development environments.
- Seamlessly support multiple programming languages and frameworks.

Checkout [Github repo](https://github.com/liauto-siada/siada-cli) to start using it today!

# Performance
```
Submission summary for 20250903_Siada_claude-4-sonnet on SWE-bench lite split
==================================================
Resolved 173 instances (57.67%)
==================================================
Resolved by Repository
- astropy/astropy: 3/6 (50.0%)
- django/django: 76/114 (66.67%)
- matplotlib/matplotlib: 15/23 (65.22%)
- mwaskom/seaborn: 2/4 (50.0%)
- pallets/flask: 0/3 (0.0%)
- psf/requests: 3/6 (50.0%)
- pydata/xarray: 1/5 (20.0%)
- pylint-dev/pylint: 3/6 (50.0%)
- pytest-dev/pytest: 7/17 (41.18%)
- scikit-learn/scikit-learn: 17/23 (73.91%)
- sphinx-doc/sphinx: 6/16 (37.5%)
- sympy/sympy: 40/77 (51.95%)
==================================================
Resolved by Time
- 2012: 1/1 (100.0%)
- 2014: 1/3 (33.33%)
- 2015: 0/1 (0.0%)
- 2016: 2/4 (50.0%)
- 2017: 7/16 (43.75%)
- 2018: 11/21 (52.38%)
- 2019: 39/59 (66.1%)
- 2020: 34/66 (51.52%)
- 2021: 26/42 (61.9%)
- 2022: 37/57 (64.91%)
- 2023: 15/30 (50.0%)
```

# Details

### Why does  exist?

`Siada CLI` is a command-line based code generation tool, similar to `gemini-cli` and `claude-code`, built upon Large Language Models (LLMs) and Agent-based design.

Software development is a systematic engineering process that encompasses multiple stages, including design, coding, testing, deployment, and operations. Although code implementation is a critical component, engineers often spend a significant amount of time on non-coding tasks such as requirement analysis, design reviews, and debugging.

We believe that current AI capabilities have the potential to revolutionize software development efficiency, but this potential should not be confined to just the code generation phase. We believe many peers in the industry share a similar view.  LLM-based code generation tools have the potential to empower the entire software development lifecycle, which is the reason for the creation and open-sourcing of `Siada CLI`.

Looking at the software development lifecycle, it is noteworthy that these seemingly distinct stages actually share a common foundation of capabilities—they all require fundamental computer science literacy, an understanding of the project's context, and even coding skills. For example, architectural design requires an assessment of the new feature's impact on the existing system, writing test cases demands an understanding of the business logic within the code, and operational troubleshooting also relies on the ability to read code.

This commonality in required capabilities suggests that job roles are merely superficial; the underlying skills and objectives are what truly matter. The various intelligent code tools currently available in the industry possess precisely these capabilities. In `Siada CLI`, we have developed a **"delegation mode,"** which allows for end-to-end task completion without the need for multiple rounds of human interaction, currently limited to code development-related tasks. `Siada CLI` currently provides a `CodeGenAgent` with basic programming abilities, adopting an Agentic model and using Openrouter to connect to the models. It supports both delegation and non-delegation modes. In the future, more task-specific scenarios will be developed based on the `CodeGenAgent`.

### Regarding the reproduction of Swe-bench

#### BugFixAgent

The `BugFixAgent` is an agent extended from the `CodeGenAgent`, specifically focused on the domain of bug fixing. Compared to the base `CodeGenAgent`, the `BugFixAgent` has the following main differences:

1.  **Optimizes the bug description:** Similar to prompt optimization, it makes the semantics of the bug description clearer and more complete.
2.  **Performs automatic independent verification after task completion:** When the agent determines that the bug has been fixed, it runs an automatic check. For tasks that fail this verification, it will attempt to fix them again based on the verification results.
3.  **Attempts to reproduce the bug and test the fix:** At the beginning and end of the bug-fixing process, it tries to reproduce the bug and then uses test cases to verify the fix. This part is controlled by the prompt.

#### Reproduction Method

1.  Install `siada-cli` by following the user guide.
2.  Execute the bug-fixing command:
    ```bash
    siada-cli --bugfix --prompt <issue_description>
    ```
    * Here, `<issue_description>` is the "problem statement" from swe-bench.
3.  Use `git diff` to obtain the fix patch. Apply this patch to the original repository containing the issue and run the test cases.


This submission is made with Siada CLI v1.2.0 at commit `7d9dfa867c14ce8198c67421543c1952414fe30e` of the branch main using `anthropic/claude-sonnet-4-20250514`.


# Checklist
- ✅ Is a pass@1 submission (does not attempt the same task instance more than once)
- ✅ Does not use SWE-bench test knowledge (`PASS_TO_PASS`, `FAIL_TO_PASS`)
- ✅ Does not use the `hints` field in SWE-bench
- ✅ Does not have web-browsing OR has taken steps to prevent lookup of SWE-bench solutions via web-browsing

</div>