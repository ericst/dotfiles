#!/usr/bin/env python3
"""Personal dotfiles manager — symlink-based package installer."""

import argparse
import os
import sys
import tomllib
from pathlib import Path

INSTALL_FILE = "install.toml"
DESCRIPTION_FILE = "description.txt"
NOTES_FILE = "notes.txt"

# Global options (mirrors Ruby's $options)
options: dict = {}

REPO_ROOT = Path(__file__).parent.resolve()


# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------


def validate_source_file(source_path: Path) -> None:
    if not source_path.exists():
        raise SystemExit(f"Source file does not exist: {source_path}")
    if not os.access(source_path, os.R_OK):
        raise SystemExit(f"Source file is not readable: {source_path}")


def validate_target_path(target_path: str) -> Path:
    if "../" in target_path or "..\\" in target_path:
        raise SystemExit(f"Directory traversal detected in target path: {target_path}")

    expanded = Path(target_path).expanduser()

    if not expanded.is_absolute():
        raise SystemExit(f"Target path must resolve to an absolute path: {target_path}")

    return expanded


# ---------------------------------------------------------------------------
# Confirmation prompt
# ---------------------------------------------------------------------------


def confirm_destructive(message: str, auto_yes: bool = False) -> bool:
    if auto_yes or options.get("auto_yes"):
        return True

    answer = input(f"{message} (y/n/a/q): ").strip().lower()

    if answer in ("y", "yes"):
        return True
    elif answer in ("a", "all"):
        options["auto_yes"] = True
        return True
    elif answer in ("q", "quit"):
        print("Operation cancelled by user")
        sys.exit(1)
    else:
        return False


# ---------------------------------------------------------------------------
# Low-level symlink creation
# ---------------------------------------------------------------------------


def _symlink(src: Path, dst: Path) -> None:
    if options.get("dry_run"):
        print(f"[DRY RUN] Would create directory: {dst.parent}")
        print(f"[DRY RUN] Would create symlink: {dst} -> {src}")
    else:
        dst.parent.mkdir(parents=True, exist_ok=True)
        print(f"mkdir -p {dst.parent}")
        dst.symlink_to(src)
        print(f"ln -s {src} {dst}")


# ---------------------------------------------------------------------------
# High-level link helpers
# ---------------------------------------------------------------------------


def link(src_str: str, dst_str: str) -> None:
    """Create a single symlink from dst -> src, handling conflicts."""
    src = Path(src_str).expanduser().resolve()
    dst = validate_target_path(dst_str)

    validate_source_file(src)

    if dst.exists() or dst.is_symlink():
        if dst.is_symlink():
            current_target = dst.resolve()
            if current_target == src:
                print(f"{dst} already links to {src}, nothing to do")
                return
            else:
                if options.get("dry_run"):
                    print(f"[DRY RUN] Would replace existing symlink {dst} -> {src}")
                elif confirm_destructive(f"Replace existing symlink {dst}?"):
                    print(f"Unlinking {dst}")
                    dst.unlink()
                    _symlink(src, dst)
                else:
                    print(f"Skipping {dst}")
        else:
            # Real file / directory — needs --force
            if options.get("force"):
                if options.get("dry_run"):
                    print(
                        f"[DRY RUN] Would delete existing file {dst} and create symlink -> {src}"
                    )
                elif confirm_destructive(
                    f"{dst} exists and is not a symlink. Delete it?"
                ):
                    print(f"{dst} exists, forcing install, deleting it")
                    if dst.is_dir():
                        import shutil

                        shutil.rmtree(dst)
                    else:
                        dst.unlink()
                    _symlink(src, dst)
                else:
                    print(f"Skipping {dst}")
            else:
                if options.get("dry_run"):
                    print(f"[DRY RUN] Would fail: {dst} exists and is not a symlink")
                else:
                    raise SystemExit(
                        f"{dst} exists and is not a symlink. "
                        "Use --force to overwrite, or remove it manually"
                    )
    else:
        _symlink(src, dst)


def link_files_recursively(src_str: str, dst_str: str) -> None:
    """Walk src_dir and symlink every file individually into dst_dir."""
    src = Path(src_str).expanduser().resolve()

    if not src.is_dir():
        raise SystemExit(f"Source directory does not exist: {src}")

    dst_base = validate_target_path(dst_str)

    for source_file in sorted(src.rglob("*")):
        if source_file.is_dir():
            continue
        relative = source_file.relative_to(src)
        target_file = dst_base / relative
        link(str(source_file), str(target_file))


# ---------------------------------------------------------------------------
# Package discovery
# ---------------------------------------------------------------------------


def get_available_packages() -> list[str]:
    packages_dir = REPO_ROOT / "packages"
    if not packages_dir.is_dir():
        return []
    return sorted(entry.name for entry in packages_dir.iterdir() if entry.is_dir())


def get_package_description(package: str) -> str:
    desc_file = REPO_ROOT / "packages" / package / DESCRIPTION_FILE
    if desc_file.exists() and os.access(desc_file, os.R_OK):
        return desc_file.read_text().strip()
    return "No description available"


def display_package_notes(package: str) -> None:
    notes_file = REPO_ROOT / "packages" / package / NOTES_FILE
    if notes_file.exists() and os.access(notes_file, os.R_OK):
        print("[NOTES]")
        print(notes_file.read_text())


def package_has_installer(package: str) -> bool:
    install_file = REPO_ROOT / "packages" / package / INSTALL_FILE
    return install_file.exists() and os.access(install_file, os.R_OK)


# ---------------------------------------------------------------------------
# TOML link spec loader
# ---------------------------------------------------------------------------


def get_package_links(package: str) -> list[dict]:
    """Parse install.toml and return a list of link descriptors."""
    install_file = REPO_ROOT / "packages" / package / INSTALL_FILE
    if not install_file.exists():
        return []

    with install_file.open("rb") as f:
        data = tomllib.load(f)

    package_dir = REPO_ROOT / "packages" / package
    links = []

    for entry in data.get("links", []):
        src = (package_dir / entry["source"]).resolve()
        dst = Path(entry["target"]).expanduser()
        recursive = entry.get("recursive", False)
        links.append(
            {
                "source": src,
                "target": dst,
                "type": "recursive" if recursive else "file",
            }
        )

    return links


# ---------------------------------------------------------------------------
# Install / uninstall
# ---------------------------------------------------------------------------


def install_package(package: str) -> None:
    print("--------------------------------------")
    prefix = "[DRY RUN] " if options.get("dry_run") else ""
    print(f"{prefix}Installing package: {package}")

    package_path = REPO_ROOT / "packages" / package
    if not package_path.is_dir():
        raise SystemExit(
            f"Package directory does not exist: {package_path}\n"
            f"Available packages: {', '.join(get_available_packages())}"
        )

    if not package_has_installer(package):
        raise SystemExit(
            f"Couldn't find or read {INSTALL_FILE} for package {package}\n"
            "Make sure the file exists and is readable"
        )

    for entry in get_package_links(package):
        if entry["type"] == "recursive":
            link_files_recursively(str(entry["source"]), str(entry["target"]))
        else:
            link(str(entry["source"]), str(entry["target"]))

    print(f"{prefix}Done installing: {package}")
    display_package_notes(package)


def uninstall_package(package: str) -> None:
    print("--------------------------------------")
    prefix = "[DRY RUN] " if options.get("dry_run") else ""
    print(f"{prefix}Uninstalling package: {package}")

    package_path = REPO_ROOT / "packages" / package
    if not package_path.is_dir():
        raise SystemExit(
            f"Package directory does not exist: {package_path}\n"
            f"Available packages: {', '.join(get_available_packages())}"
        )

    links = get_package_links(package)
    if not links:
        print(f"No links found for package {package}")
        return

    removed = 0
    skipped = 0

    for entry in links:
        dst = entry["target"]

        if entry["type"] == "recursive":
            if dst.is_dir():
                if options.get("dry_run"):
                    print(f"[DRY RUN] Would remove directory: {dst}")
                    removed += 1
                elif confirm_destructive(f"Remove directory {dst}?"):
                    import shutil

                    print(f"Removing directory: {dst}")
                    shutil.rmtree(dst)
                    removed += 1
                else:
                    print(f"Skipping directory: {dst}")
                    skipped += 1
            else:
                print(f"Directory already missing: {dst}")
        else:
            if dst.exists() or dst.is_symlink():
                if dst.is_symlink():
                    if dst.resolve() == entry["source"]:
                        if options.get("dry_run"):
                            print(f"[DRY RUN] Would remove symlink: {dst}")
                            removed += 1
                        else:
                            print(f"Removing symlink: {dst}")
                            dst.unlink()
                            removed += 1
                    else:
                        print(
                            f"Skipping {dst} (points to different target: {dst.readlink()})"
                        )
                        skipped += 1
                else:
                    print(f"Skipping {dst} (not a symlink)")
                    skipped += 1
            else:
                print(f"File already missing: {dst}")

    print(
        f"{prefix}Done uninstalling: {package} (removed {removed}, skipped {skipped})"
    )


# ---------------------------------------------------------------------------
# List / status
# ---------------------------------------------------------------------------


def list_packages() -> None:
    print("Available packages:")
    print("===================")

    packages = get_available_packages()
    if not packages:
        print("No packages found in packages/ directory")
        return

    for pkg in packages:
        desc = get_package_description(pkg)
        indicator = "✓" if package_has_installer(pkg) else "✗"
        print(f"{indicator} {pkg:<15} - {desc}")

    print(f"\n✓ = Has {INSTALL_FILE}, ✗ = Missing {INSTALL_FILE}")


def check_package_status(package: str) -> dict:
    if not package_has_installer(package):
        return {"status": "no_installer", "links": []}

    links = get_package_links(package)
    link_statuses = []

    for entry in links:
        dst = entry["target"]

        if entry["type"] == "recursive":
            if dst.is_dir():
                link_statuses.append(
                    {
                        "target": dst,
                        "status": "installed",
                        "type": "recursive",
                        "note": "Directory exists (recursive link)",
                    }
                )
            else:
                link_statuses.append(
                    {
                        "target": dst,
                        "status": "missing",
                        "type": "recursive",
                        "note": "Directory missing",
                    }
                )
        else:
            if dst.exists() or dst.is_symlink():
                if dst.is_symlink():
                    if dst.resolve() == entry["source"]:
                        link_statuses.append(
                            {
                                "target": dst,
                                "status": "installed",
                                "type": "file",
                                "note": "Correctly linked",
                            }
                        )
                    else:
                        link_statuses.append(
                            {
                                "target": dst,
                                "status": "wrong_target",
                                "type": "file",
                                "note": f"Links to wrong target: {dst.readlink()}",
                            }
                        )
                else:
                    link_statuses.append(
                        {
                            "target": dst,
                            "status": "not_symlink",
                            "type": "file",
                            "note": "File exists but is not a symlink",
                        }
                    )
            else:
                link_statuses.append(
                    {
                        "target": dst,
                        "status": "missing",
                        "type": "file",
                        "note": "File missing",
                    }
                )

    if not link_statuses:
        overall = "no_links"
    elif all(ls["status"] == "installed" for ls in link_statuses):
        overall = "fully_installed"
    elif any(ls["status"] == "installed" for ls in link_statuses):
        overall = "partially_installed"
    else:
        overall = "not_installed"

    return {"status": overall, "links": link_statuses}


def show_status() -> None:
    print("Package installation status:")
    print("=============================")

    packages = get_available_packages()
    if not packages:
        print("No packages found in packages/ directory")
        return

    for pkg in packages:
        info = check_package_status(pkg)
        status = info["status"]

        if status == "no_installer":
            print(f"✗ {pkg:<15} - No {INSTALL_FILE} file")
        elif status == "no_links":
            print(f"? {pkg:<15} - No links defined")
        elif status == "fully_installed":
            print(f"✓ {pkg:<15} - Fully installed ({len(info['links'])} links)")
        elif status == "partially_installed":
            installed = sum(1 for l in info["links"] if l["status"] == "installed")
            total = len(info["links"])
            print(f"~ {pkg:<15} - Partially installed ({installed}/{total} links)")
            for lnk in info["links"]:
                if lnk["status"] != "installed":
                    print(f"    {lnk['target']} - {lnk['note']}")
        elif status == "not_installed":
            print(f"✗ {pkg:<15} - Not installed ({len(info['links'])} links missing)")
            for lnk in info["links"]:
                if lnk["status"] != "installed":
                    print(f"    {lnk['target']} - {lnk['note']}")

    print(
        "\n✓ = Fully installed, ~ = Partially installed, ✗ = Not installed, ? = No links"
    )


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="dotfiles",
        description="Install or uninstall dotfile packages by creating/removing symlinks.",
        usage="dotfiles [options] packages...",
    )
    parser.add_argument(
        "-f", "--force", action="store_true", help="Force the installation"
    )
    parser.add_argument(
        "-l", "--list", action="store_true", help="List available packages"
    )
    parser.add_argument(
        "-s",
        "--status",
        action="store_true",
        help="Show installation status of packages",
    )
    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="Automatically answer yes to all prompts",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Show what would be done without executing",
    )
    parser.add_argument(
        "-u",
        "--uninstall",
        action="store_true",
        help="Uninstall packages instead of installing them",
    )
    parser.add_argument("packages", nargs="*", help="Packages to install/uninstall")

    args = parser.parse_args()

    options["force"] = args.force
    options["auto_yes"] = args.yes
    options["dry_run"] = args.dry_run

    if args.list:
        list_packages()
        return

    if args.status:
        show_status()
        return

    if not args.packages:
        parser.error("You need to specify at least one package")

    for pkg in args.packages:
        if args.uninstall:
            uninstall_package(pkg)
        else:
            install_package(pkg)


if __name__ == "__main__":
    main()
