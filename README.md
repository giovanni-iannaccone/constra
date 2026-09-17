# 🔎 Constra

Constra is an Emacs package for looking up and composing C constants while reverse engineering binaries. It lets you decode numeric values back into the C constants they represent, using a database generated automatically from Linux headers. Intended to keep this whole workflow inside Emacs, without having to jump between your disassembler, local headers, `grep`, and a browser every time you encounter a suspicious hexadecimal value.

## ✨ Features

- Look up numeric constants with `M-x constra-lookup`
- Compose multiple constants with `M-x constra-compose`
- Generate the database automatically from Linux headers with `M-x constra-generate`
- Organize constants into contexts and groups
- Inspect available contexts and groups with `M-x constra-describe-context`
- Generate constants directly from the headers available on your Linux system
- Keep the entire lookup workflow inside Emacs

## 📋 Requirements

- Emacs
- Linux headers available on the system when generating the database

## 📦 Installation

Clone the repository and add it to your Emacs `load-path`, or install it using your preferred Emacs package manager.
Then load Constra:
```
(require 'constra)
```

The exact installation method depends on how you manage your Emacs configuration.

## 🏗️ Generating the database

Constra generates its database automatically from Linux headers, so there is no need to maintain a giant list of constants by hand. Run:
```
M-x constra-generate RET
```

This generates the database used by Constra for subsequent lookups. If you switch to a different set of Linux headers or want to update the available constants, simply regenerate the database.

## 🚀 Usage

The interactive commands are:

| Command                        | Description                                        |
| ------------------------------ | -------------------------------------------------- |
| `M-x constra-generate`         | Generate the constants database from Linux headers |
| `M-x constra-lookup`           | Look up a numeric constant                         |
| `M-x constra-compose`          | Compose multiple constants into a numeric value    |
| `M-x constra-describe-context` | Inspect a context and its groups                   |

## 🔍 Looking up constants

When reverse engineering a binary, you often end up with numeric values whose meaning is hidden behind a C macro. For example:
```
mmap(addr, length, 0x5, flags, fd, offset);
```
What the hell is `0x5`?

Run:
```
M-x constra-lookup RET
```
Constra lets you select a context and enter the numeric value you want to decode. It then searches the database and displays matching constants, including their value, expression, description, and any unknown bits.

This is especially useful when dealing with syscall arguments, flags, bitmasks, and other constants commonly encountered during reverse engineering.

## 🧩 Composing constants

Constra also works in the opposite direction. Sometimes you know that a value is made up of several flags and want to know what numeric value they produce. Run:
```
M-x constra-compose RET
```

You first select a context and group, then interactively select the constants you want to combine. For example, instead of manually calculating:
```
FLAG_A | FLAG_B | FLAG_C
```

Constra can compose the flags and show you:
```
Value: 13
Expression: FLAG_A | FLAG_B | FLAG_C
```

along with the individual constants and their numeric values. This is useful when reconstructing function calls or syscall arguments from a binary.

## 📚 Contexts and groups

Constra organizes constants into two main concepts: contexts and groups. A **context** represents a namespace or broader collection of related constants. A **group** contains constants that belong together, such as a collection of flags that can be combined into a bitmask. You can inspect the available contexts and their groups with:
```
M-x constra-describe-context RET
```
Constra will show the groups available in the selected context, together with their type and the number of constants they contain.

## ⚖️ License

This project is licensed under the GPL-3.0 License. See the LICENSE file for details.
