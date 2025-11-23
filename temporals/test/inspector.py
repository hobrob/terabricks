
import inspect
import importlib
import argparse


def inspect_module(module_name, output_file):
    try:
        module = importlib.import_module(module_name)
    except ImportError:
        print(f"Module '{module_name}' not found.")
        return

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(f"# Module: `{module_name}`\n\n")

        # Inspect classes
        f.write("## 🧩 Classes\n\n")
        for name, obj in inspect.getmembers(module, inspect.isclass):
            if obj.__module__.startswith(module_name):
                f.write(f"### `{name}`\n\n")
                f.write(f"**Docstring:**\n```\n{inspect.getdoc(obj) or 'None'}\n```\n\n")

        # Inspect functions
        f.write("## ⚙️ Functions\n\n")
        for name, obj in inspect.getmembers(module, inspect.isfunction):
            if obj.__module__.startswith(module_name):
                sig = inspect.signature(obj)
                f.write(f"### `{name}{sig}`\n\n")
                f.write(f"**Docstring:**\n```\n{inspect.getdoc(obj) or 'None'}\n```\n\n")

    print(f"Inspection complete. Results saved to '{output_file}'.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Inspect a Python module and export results as Markdown.")
    parser.add_argument("module_name", help="Name of the module to inspect (e.g., azure.identity)")
    parser.add_argument("--output", default="module_docs.md", help="Output Markdown file (default: module_docs.md)")
    args = parser.parse_args()

    inspect_module(args.module_name, args.output)
