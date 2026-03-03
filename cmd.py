#!/usr/bin/env python3
"""
Slote Unified Command Tool

A cross-platform command-line interface for database operations and emulator management.
"""

import argparse
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Constants
PACKAGE_NAME = "com.example.slote"
DB_NAME = "notes.db"
REMOTE_PATH = f"/data/data/{PACKAGE_NAME}/app_flutter/{DB_NAME}"
DEFAULT_EMULATOR = "Medium_Phone_API_36.1"


def die(message):
    """Print error message and exit."""
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


def info(message):
    """Print info message."""
    print(message, file=sys.stderr)


def command_exists(command):
    """Check if a command exists in PATH."""
    return shutil.which(command) is not None


def detect_platform():
    """Detect the current platform."""
    system = platform.system().lower()
    if system == "darwin":
        return "macos"
    elif system == "linux":
        return "linux"
    elif system == "windows":
        return "windows"
    else:
        return "unknown"


def get_android_sdk_path():
    """Get Android SDK path from environment or default locations."""
    # Check environment variables first
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if android_home:
        return android_home
    
    # Default locations
    platform_type = detect_platform()
    home = Path.home()
    
    if platform_type == "windows":
        # Try common Windows locations
        local_appdata = os.environ.get("LOCALAPPDATA")
        if local_appdata:
            sdk_path = Path(local_appdata) / "Android" / "Sdk"
            if sdk_path.exists():
                return str(sdk_path)
        
        userprofile = os.environ.get("USERPROFILE")
        if userprofile:
            sdk_path = Path(userprofile) / "Android" / "Sdk"
            if sdk_path.exists():
                return str(sdk_path)
    else:
        # macOS/Linux
        sdk_path = home / "Android" / "Sdk"
        if sdk_path.exists():
            return str(sdk_path)
    
    # Return default even if it doesn't exist (for error messages)
    if platform_type == "windows":
        return str(Path(os.environ.get("LOCALAPPDATA", "")) / "Android" / "Sdk")
    else:
        return str(home / "Android" / "Sdk")


def android_available():
    """Check if Android device/emulator is available."""
    if not command_exists("adb"):
        return False
    try:
        result = subprocess.run(
            ["adb", "devices"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return bool(re.search(r"device\s*$", result.stdout, re.MULTILINE))
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def android_pick_device(device_id=None):
    """Pick Android device ID."""
    if device_id:
        return device_id
    
    try:
        result = subprocess.run(
            ["adb", "devices"],
            capture_output=True,
            text=True,
            timeout=5
        )
        matches = re.findall(r"^(\S+)\s+device\s*$", result.stdout, re.MULTILINE)
        if matches:
            return matches[0]
        die("No Android devices connected")
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        die(f"Failed to list Android devices: {e}")


def android_assert_installed(device_id):
    """Assert that the app is installed on the device."""
    try:
        result = subprocess.run(
            ["adb", "-s", device_id, "shell", "pm", "list", "packages"],
            capture_output=True,
            text=True,
            timeout=10
        )
        if PACKAGE_NAME not in result.stdout:
            die(f"Package {PACKAGE_NAME} is not installed on device {device_id}")
    except subprocess.TimeoutExpired:
        die(f"Timeout checking if package is installed on device {device_id}")


def android_pull_db(device_id, output_file):
    """Pull database from Android device."""
    info(f"Pulling database from Android device {device_id}...")
    try:
        with open(output_file, "wb") as f:
            result = subprocess.run(
                ["adb", "-s", device_id, "exec-out", "run-as", PACKAGE_NAME, "cat", REMOTE_PATH],
                stdout=f,
                stderr=subprocess.PIPE,
                timeout=30
            )
            if result.returncode != 0:
                die(f"Failed to pull database via ADB. (Is this a debuggable build? Does run-as work?)\n{result.stderr.decode()}")
        
        if not os.path.exists(output_file) or os.path.getsize(output_file) == 0:
            die(f"Pulled database file is missing/empty: {output_file}")
        
        info(f"Database pulled successfully: {output_file}")
    except subprocess.TimeoutExpired:
        die("Timeout pulling database from device")
    except Exception as e:
        die(f"Failed to pull database: {e}")


def android_push_db(device_id, db_file):
    """Push database to Android device."""
    if not os.path.exists(db_file):
        die(f"Database file not found: {db_file}")
    
    info(f"Pushing database to Android device {device_id}...")
    
    # Push to /data/local/tmp/ which is accessible to both adb and run-as
    import tempfile
    temp_filename = f"notes_{os.getpid()}.db"
    temp_path = f"/data/local/tmp/{temp_filename}"
    
    try:
        # Push file to /data/local/tmp/ (accessible to run-as)
        result = subprocess.run(
            ["adb", "-s", device_id, "push", db_file, temp_path],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode != 0:
            die(f"Failed to push database to device: {result.stderr}")
        
        # Copy to app directory with proper permissions using run-as
        # Use cat with absolute path (more reliable than cp in run-as context)
        dest_path = f"/data/data/{PACKAGE_NAME}/app_flutter/{DB_NAME}"
        copy_cmd = f"run-as {PACKAGE_NAME} sh -c 'cat {temp_path} > {dest_path}'"
        result = subprocess.run(
            ["adb", "-s", device_id, "shell", copy_cmd],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            # Clean up temp file
            subprocess.run(["adb", "-s", device_id, "shell", f"rm {temp_path}"], timeout=5, stderr=subprocess.DEVNULL)
            error_msg = result.stderr.strip() or result.stdout.strip()
            if not error_msg:
                error_msg = "Unknown error (check if app is debuggable and installed)"
            die(f"Failed to copy database to app directory: {error_msg}\n\nNote: Make sure the app is a debuggable build and the app is installed on the device.")
        
        # Clean up temp file
        subprocess.run(["adb", "-s", device_id, "shell", f"rm {temp_path}"], timeout=5, stderr=subprocess.DEVNULL)
        info("Database pushed successfully. Restart the app to see changes.")
    except subprocess.TimeoutExpired:
        die("Timeout pushing database to device")
    except Exception as e:
        die(f"Failed to push database: {e}")


def ios_simulator_db_path():
    """Get iOS simulator database path."""
    if not command_exists("xcrun"):
        die("xcrun not found. Install Xcode command line tools.")
    
    try:
        result = subprocess.run(
            ["xcrun", "simctl", "get_app_container", "booted", PACKAGE_NAME, "data"],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            die(f"No booted iOS simulator with {PACKAGE_NAME} installed (or not running).\n{result.stderr}")
        
        container = result.stdout.strip()
        if not container:
            die("No booted iOS simulator with app installed")
        
        db_path = os.path.join(container, "Documents", DB_NAME)
        return db_path
    except subprocess.TimeoutExpired:
        die("Timeout getting iOS simulator container path")
    except Exception as e:
        die(f"Failed to get iOS simulator path: {e}")


def host_candidate_db_paths():
    """Get candidate database paths for host platform."""
    platform_type = detect_platform()
    home = Path.home()
    paths = []
    
    if platform_type == "macos":
        paths.append(home / "Library" / "Containers" / PACKAGE_NAME / "Data" / "Documents" / DB_NAME)
    elif platform_type == "linux":
        xdg_data_home = os.environ.get("XDG_DATA_HOME")
        if xdg_data_home:
            paths.append(Path(xdg_data_home) / PACKAGE_NAME / DB_NAME)
        paths.append(home / ".local" / "share" / PACKAGE_NAME / DB_NAME)
        paths.append(home / "Documents" / DB_NAME)
    elif platform_type == "windows":
        local_appdata = os.environ.get("LOCALAPPDATA")
        if local_appdata:
            paths.append(Path(local_appdata.replace("\\", "/")) / PACKAGE_NAME / "Data" / "Documents" / DB_NAME)
        appdata = os.environ.get("APPDATA")
        if appdata:
            paths.append(Path(appdata.replace("\\", "/")) / PACKAGE_NAME / "Data" / "Documents" / DB_NAME)
        paths.append(home / "Documents" / DB_NAME)
    
    return [str(p) for p in paths]


def host_find_db():
    """Find database file on host platform."""
    for path in host_candidate_db_paths():
        if os.path.isfile(path):
            return path
    return None


def open_in_db_browser(db_path):
    """Open database file in DB Browser for SQLite."""
    if not os.path.isfile(db_path):
        die(f"Database file not found: {db_path}")
    
    platform_type = detect_platform()
    
    # macOS: Try app bundle first
    if platform_type == "macos":
        app_path = "/Applications/DB Browser for SQLite.app"
        if os.path.isdir(app_path):
            info("Opening in DB Browser for SQLite...")
            subprocess.run(["open", "-a", "DB Browser for SQLite", db_path])
            return
    
    # Try sqlitebrowser command
    if command_exists("sqlitebrowser"):
        info("Opening in DB Browser for SQLite...")
        subprocess.run(["sqlitebrowser", db_path])
        return
    
    # Try db-browser-for-sqlite command
    if command_exists("db-browser-for-sqlite"):
        info("Opening in DB Browser for SQLite...")
        subprocess.run(["db-browser-for-sqlite", db_path])
        return
    
    # Windows: Try cmd start as fallback
    if platform_type == "windows":
        info("Opening in default app...")
        subprocess.run(["cmd.exe", "/c", "start", "", db_path], shell=True)
        return
    
    die(f"DB Browser for SQLite not found. Install it, then open manually: {db_path}")


def cmd_db_open(args):
    """Handle 'db open' command."""
    mode = args.mode or "auto"
    
    if mode == "web":
        print("Web uses IndexedDB (not a SQLite file), so there is no `notes.db` to open.")
        print("\nRecommended options:")
        print("  - Use your browser DevTools -> Application/Storage -> IndexedDB to inspect data.")
        print("  - Or add an explicit export feature in-app if you need a SQLite dump.")
        return
    
    if mode == "android":
        device_id = android_pick_device(args.device_id)
        output_file = args.output_file or DB_NAME
        android_assert_installed(device_id)
        android_pull_db(device_id, output_file)
        open_in_db_browser(output_file)
    elif mode == "ios":
        db_path = ios_simulator_db_path()
        open_in_db_browser(db_path)
    elif mode == "host":
        if args.db_path:
            db_path = args.db_path
        else:
            db_path = host_find_db()
            if not db_path:
                platform_type = detect_platform()
                python_cmd = "python3" if platform_type != "windows" else "python"
                die(f"Could not find {DB_NAME} on host ({platform_type}). Pass an explicit path: {python_cmd} cmd.py db open host /path/to/notes.db")
        open_in_db_browser(db_path)
    elif mode == "auto":
        # Auto mode: prefer Android if available, otherwise host
        if android_available():
            device_id = android_pick_device()
            output_file = DB_NAME
            android_assert_installed(device_id)
            android_pull_db(device_id, output_file)
            open_in_db_browser(output_file)
        else:
            platform_type = detect_platform()
            if platform_type == "unknown":
                die(f"Unsupported host OS. Use explicit mode: android | ios | host")
            db_path = host_find_db()
            if not db_path:
                python_cmd = "python3" if platform_type != "windows" else "python"
                die(f"Could not find {DB_NAME} on host ({platform_type}). Pass an explicit path: {python_cmd} cmd.py db open host /path/to/notes.db")
            open_in_db_browser(db_path)
    else:
        die(f"Unknown mode '{mode}'. Use: android | ios | host | web | auto")
    
    info("Done!")


def cmd_db_push(args):
    """Handle 'db push' command."""
    platform_type = args.platform or "android"
    
    if platform_type != "android":
        die(f"Push currently only supports Android. Requested: {platform_type}")
    
    device_id = android_pick_device(args.device_id)
    db_file = args.db_file or DB_NAME
    
    android_assert_installed(device_id)
    android_push_db(device_id, db_file)


def cmd_emulator_launch(args):
    """Handle 'emulator launch' command."""
    emulator_name = args.name or DEFAULT_EMULATOR
    
    # Set Android SDK environment variables
    android_sdk = get_android_sdk_path()
    env = os.environ.copy()
    env["ANDROID_HOME"] = android_sdk
    env["ANDROID_SDK_ROOT"] = android_sdk
    
    info(f"Launching emulator: {emulator_name}")
    info(f"ANDROID_HOME: {android_sdk}")
    info(f"ANDROID_SDK_ROOT: {android_sdk}")
    print()
    
    # Try Flutter command first
    try:
        result = subprocess.run(
            ["flutter", "emulators", "--launch", emulator_name],
            env=env,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        print("=== Flutter Command Output ===")
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
        print()
        
        # Check for error patterns
        output_lower = (result.stdout + result.stderr).lower()
        has_error = (
            result.returncode != 0 or
            "exited with code" in output_lower or
            "address these issues" in output_lower or
            "error" in output_lower
        )
        
        if has_error:
            info("=== ERROR: Emulator launch failed ===")
            info("Attempting direct emulator launch as fallback...")
            print()
            _launch_emulator_direct(emulator_name, android_sdk, env)
        else:
            info("✓ Emulator launch command completed successfully")
            info("Note: The emulator may take 30-60 seconds to fully boot")
            info("Check status with: flutter devices")
    except subprocess.TimeoutExpired:
        die("Timeout launching emulator")
    except FileNotFoundError:
        die("Flutter not found in PATH. Please install Flutter and add it to your PATH.")


def _launch_emulator_direct(emulator_name, android_sdk, env):
    """Launch emulator directly using emulator binary."""
    platform_type = detect_platform()
    
    if platform_type == "windows":
        emulator_bin = os.path.join(android_sdk, "emulator", "emulator.exe")
    else:
        emulator_bin = os.path.join(android_sdk, "emulator", "emulator")
    
    if not os.path.isfile(emulator_bin):
        die(f"Emulator binary not found: {emulator_bin}")
    
    # Convert emulator name (spaces to underscores for AVD names)
    avd_name = emulator_name.replace(" ", "_")
    
    info(f"Attempting direct launch with AVD: {avd_name}")
    
    try:
        # List available AVDs
        result = subprocess.run(
            [emulator_bin, "-list-avds"],
            env=env,
            capture_output=True,
            text=True,
            timeout=10
        )
        print("Available AVDs:")
        print(result.stdout)
        print()
        
        # Launch emulator
        if platform_type == "windows":
            # On Windows, launch in background
            subprocess.Popen(
                [emulator_bin, "-avd", avd_name],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        else:
            # On macOS/Linux, launch in background
            subprocess.Popen(
                [emulator_bin, "-avd", avd_name],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        
        info("Direct emulator launch initiated")
        info("The emulator window should appear shortly (may take 30-60 seconds to boot)")
        info("Check status with: flutter devices")
    except Exception as e:
        die(f"Failed to launch emulator directly: {e}")


def cmd_emulator_list(args):
    """Handle 'emulator list' command."""
    try:
        result = subprocess.run(
            ["flutter", "emulators"],
            capture_output=True,
            text=True,
            timeout=30
        )
        print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
    except FileNotFoundError:
        die("Flutter not found in PATH. Please install Flutter and add it to your PATH.")
    except subprocess.TimeoutExpired:
        die("Timeout listing emulators")


def cmd_run(args):
    """Handle 'run' command - run Flutter app from repo root."""
    # Get the script's directory (root of the project)
    script_dir = Path(__file__).parent.absolute()
    app_dir = script_dir

    if not command_exists("flutter"):
        die("Flutter not found in PATH. Please install Flutter and add it to your PATH.")

    # Build flutter run command with any additional arguments
    flutter_cmd = ["flutter", "run"]

    # Add any additional arguments passed by the user
    if args.flutter_args:
        flutter_cmd.extend(args.flutter_args)

    info(f"Running Flutter app from: {app_dir}")
    info(f"Command: {' '.join(flutter_cmd)}")
    print()

    try:
        # Change to repo root and run flutter run
        subprocess.run(
            flutter_cmd,
            cwd=str(app_dir),
            check=False  # Don't raise exception on non-zero exit, let user see the output
        )
    except KeyboardInterrupt:
        info("\nFlutter run interrupted by user")
    except Exception as e:
        die(f"Failed to run Flutter app: {e}")


# Component test apps (packages that have a runnable test/ app)
COMPONENT_TEST_APPS = ["viewport", "rich_text", "draw", "undo_redo"]


def cmd_bootstrap(args):
    """Run flutter pub upgrade at repo root and in each component test app (resolve and upgrade dependencies)."""
    script_dir = Path(__file__).parent.absolute()
    if not command_exists("flutter"):
        die("Flutter not found in PATH. Please install Flutter and add it to your PATH.")

    # Root (main app)
    info("Running flutter pub upgrade at repo root...")
    result = subprocess.run(
        ["flutter", "pub", "upgrade"],
        cwd=str(script_dir),
        capture_output=True,
        text=True,
        timeout=120,
    )
    if result.returncode != 0:
        die(f"flutter pub upgrade failed at root:\n{result.stderr or result.stdout}")
    info("Done at root.")

    # Each component test app
    for name in COMPONENT_TEST_APPS:
        test_dir = script_dir / "components" / name / "test"
        if not test_dir.exists():
            info(f"Skipping components/{name}/test (not found)")
            continue
        info(f"Running flutter pub upgrade in components/{name}/test...")
        result = subprocess.run(
            ["flutter", "pub", "upgrade"],
            cwd=str(test_dir),
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            die(f"flutter pub upgrade failed in {test_dir}:\n{result.stderr or result.stdout}")
    info("Bootstrap complete.")


def cmd_component_run(args):
    """Run a component's test app (flutter run from components/<name>/test)."""
    script_dir = Path(__file__).parent.absolute()
    name = (args.name or "").strip().lower()
    if name not in COMPONENT_TEST_APPS:
        die(f"Unknown component: {name}. Use one of: {', '.join(COMPONENT_TEST_APPS)}")

    test_dir = script_dir / "components" / name / "test"
    if not test_dir.exists():
        die(f"Component test app not found: {test_dir}")

    if not command_exists("flutter"):
        die("Flutter not found in PATH. Please install Flutter and add it to your PATH.")

    flutter_cmd = ["flutter", "run"]
    if getattr(args, "flutter_args", None):
        flutter_cmd.extend(args.flutter_args)

    info(f"Running component test app from: {test_dir}")
    try:
        subprocess.run(
            flutter_cmd,
            cwd=str(test_dir),
            check=False,
        )
    except KeyboardInterrupt:
        info("\nInterrupted by user")
    except Exception as e:
        die(f"Failed to run component test app: {e}")


def cmd_test(args):
    """Run flutter test at repo root and in each component test app. Fails if any fail."""
    script_dir = Path(__file__).parent.absolute()
    if not command_exists("flutter"):
        die("Flutter not found in PATH. Please install Flutter and add it to your PATH.")

    failed = []

    # Root (main app)
    info("Running flutter test at repo root...")
    result = subprocess.run(
        ["flutter", "test"],
        cwd=str(script_dir),
        capture_output=True,
        text=True,
        timeout=300,
    )
    if result.returncode != 0:
        failed.append("repo root")
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
    else:
        info("Passed at repo root.")

    for name in COMPONENT_TEST_APPS:
        test_dir = script_dir / "components" / name / "test"
        if not test_dir.exists():
            continue
        info(f"Running flutter test in components/{name}/test...")
        result = subprocess.run(
            ["flutter", "test"],
            cwd=str(test_dir),
            capture_output=True,
            text=True,
            timeout=300,
        )
        if result.returncode != 0:
            failed.append(f"components/{name}/test")
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                print(result.stderr, file=sys.stderr)
        else:
            info(f"Passed components/{name}/test.")

    if failed:
        die(f"Tests failed in: {', '.join(failed)}")
    info("All tests passed.")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Slote Unified Command Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # Database subcommands
    db_parser = subparsers.add_parser("db", help="Database operations")
    db_subparsers = db_parser.add_subparsers(dest="db_command", help="Database commands")
    
    # db open
    db_open_parser = db_subparsers.add_parser("open", help="Open database in DB Browser")
    db_open_parser.add_argument(
        "mode",
        nargs="?",
        choices=["android", "ios", "host", "web", "auto"],
        help="Platform mode (default: auto)"
    )
    db_open_parser.add_argument(
        "--device-id",
        dest="device_id",
        help="Android device ID (for android mode)"
    )
    db_open_parser.add_argument(
        "--output-file",
        dest="output_file",
        help="Output file path (for android mode, default: notes.db)"
    )
    db_open_parser.add_argument(
        "--db-path",
        dest="db_path",
        help="Database file path (for host mode)"
    )
    db_open_parser.set_defaults(func=cmd_db_open)
    
    # db push
    db_push_parser = db_subparsers.add_parser("push", help="Push database to device")
    db_push_parser.add_argument(
        "--platform",
        choices=["android"],
        default="android",
        help="Target platform (default: android)"
    )
    db_push_parser.add_argument(
        "--device-id",
        dest="device_id",
        help="Android device ID"
    )
    db_push_parser.add_argument(
        "--db-file",
        dest="db_file",
        help="Database file to push (default: notes.db)"
    )
    db_push_parser.set_defaults(func=cmd_db_push)
    
    # Emulator subcommands
    emulator_parser = subparsers.add_parser("emulator", help="Emulator operations")
    emulator_subparsers = emulator_parser.add_subparsers(dest="emulator_command", help="Emulator commands")
    
    # emulator launch
    emulator_launch_parser = emulator_subparsers.add_parser("launch", help="Launch Android emulator")
    emulator_launch_parser.add_argument(
        "name",
        nargs="?",
        help=f"Emulator name (default: {DEFAULT_EMULATOR})"
    )
    emulator_launch_parser.set_defaults(func=cmd_emulator_launch)
    
    # emulator list
    emulator_list_parser = emulator_subparsers.add_parser("list", help="List available emulators")
    emulator_list_parser.set_defaults(func=cmd_emulator_list)
    
    # Run command
    run_parser = subparsers.add_parser("run", help="Run Flutter app from repo root")
    run_parser.add_argument(
        "flutter_args",
        nargs=argparse.REMAINDER,
        help="Additional arguments to pass to 'flutter run' (e.g., --device-id, --release)"
    )
    run_parser.set_defaults(func=cmd_run)

    # Bootstrap command
    bootstrap_parser = subparsers.add_parser(
        "bootstrap",
        help="Run flutter pub upgrade at repo root and in each component test app (resolve and upgrade deps)"
    )
    bootstrap_parser.set_defaults(func=cmd_bootstrap)

    # Component subcommands
    component_parser = subparsers.add_parser("component", help="Component test app operations")
    component_subparsers = component_parser.add_subparsers(dest="component_command", help="Component commands")

    component_run_parser = component_subparsers.add_parser(
        "run",
        help="Run a component's test app (e.g. viewport, rich_text, draw, undo_redo)"
    )
    component_run_parser.add_argument(
        "name",
        choices=COMPONENT_TEST_APPS,
        help="Component name: viewport, rich_text, draw, undo_redo",
    )
    component_run_parser.add_argument(
        "flutter_args",
        nargs=argparse.REMAINDER,
        default=[],
        help="Arguments to pass to flutter run",
    )
    component_run_parser.set_defaults(func=cmd_component_run)

    # Test command
    test_parser = subparsers.add_parser(
        "test",
        help="Run flutter test at repo root and in each component test app",
    )
    test_parser.set_defaults(func=cmd_test)
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    if hasattr(args, "func"):
        args.func(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
