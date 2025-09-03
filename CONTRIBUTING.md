Contributing to Intelli Chorus Recorder
First off, thank you for considering contributing! This is an open-source project from Unique Creators, and we welcome any help to make it more powerful and accessible for everyone.

How Can I Contribute?
There are many ways to contribute, and not all of them involve writing code.

Reporting Bugs: If you find a bug, please open an issue on our project's GitHub page. Describe the issue in detail, including the steps to reproduce it, your REAPER version, and your OS.

Suggesting Enhancements: Have an idea for a new feature or an improvement to an existing one? Open an issue and describe your suggestion.

Writing Documentation: If you think the README.md or other documentation can be improved, please let us know.

Submitting Code: If you're a developer, you can help us fix bugs or add new features.

Code Contribution Guidelines
To ensure the project remains maintainable, scalable, and accessible, please follow these guidelines when submitting code.

Project Structure
The script is broken down into several modules with specific responsibilities. Please respect this structure.

main.lua: The main entry point. It orchestrates the loading and execution of other modules.

config.lua: Contains all default settings, validation rules, and user-facing text strings. Never hard-code a string in another module.

ui_wizard.lua: Handles all user interaction. All dialogs and prompts should be in this file.

core_logic.lua: Contains the core recording and REAPER API logic. This module should not contain any UI code.

lib/utils.lua: For generic, reusable helper functions that could be used in other projects.

Coding Style
Clarity is Key: Write clean, readable code with descriptive variable and function names.

Comments: Comment your code where necessary, especially for complex logic. Use LuaDoc-style comments for functions (--[[ ... ]]).

Error Handling: Functions that can fail should return two values: ok, result. ok is a boolean (true for success, false for failure). result is the return value on success or an error message string on failure.

Accessibility First: All new features must be fully accessible. Any new user interaction must provide feedback via the utils.speak() function.

Submitting a Pull Request
Fork the repository.

Create a new branch for your feature or bugfix (git checkout -b feature/amazing-new-feature).

Make your changes, adhering to the guidelines above.

Test your changes thoroughly.

Commit your changes with a clear and descriptive commit message.

Push your branch to your fork (git push origin feature/amazing-new-feature).

Open a pull request on the main repository, explaining the changes you made.

Thank you for helping us build better tools for the audio community!