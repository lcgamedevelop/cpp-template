#!/usr/bin/env python3
"""Stage a runtime installation and publish it to the requested output directory."""

import argparse
from contextlib import contextmanager
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


@contextmanager
def lock_output(output: Path):
    """Hold a nonblocking process lock until publication or recovery finishes."""
    output.parent.mkdir(parents=True, exist_ok=True)
    with (output.parent / f".{output.name}.lock").open("a+b") as lock_file:
        if os.name == "nt":
            import msvcrt

            lock_file.seek(0, os.SEEK_END)
            if lock_file.tell() == 0:
                lock_file.write(b"\0")
                lock_file.flush()
            lock_file.seek(0)
            msvcrt.locking(lock_file.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl

            fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield


def export_app(cmake: str, build_dir: Path, configuration: str, output: Path) -> None:
    """Replace an export only after its complete installation succeeds."""
    with lock_output(output):
        staging = Path(tempfile.mkdtemp(prefix=f".{output.name}-", dir=output.parent))
        backup = staging / "previous"
        preserve_backup = False
        try:
            subprocess.run(
                [cmake, "--install", str(build_dir), "--config", configuration,
                 "--prefix", str(staging), "--component", "runtime"],
                check=True,
            )
            candidate = staging / "runtime"
            if not candidate.is_dir():
                raise OSError("The runtime installation did not produce an application directory")

            if output.exists():
                output.rename(backup)
            try:
                candidate.rename(output)
            except OSError as publish_error:
                if backup.exists():
                    try:
                        backup.rename(output)
                    except OSError as restore_error:
                        preserve_backup = True
                        raise OSError(
                            f"Publication failed: {publish_error}. Recovery failed: {restore_error}. "
                            f"Previous export preserved at {backup}"
                        ) from restore_error
                raise
        finally:
            if not preserve_backup:
                shutil.rmtree(staging)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cmake", required=True)
    parser.add_argument("--build-dir", required=True, type=Path)
    parser.add_argument("--config", required=True)
    parser.add_argument("--output", required=True, type=Path)
    arguments = parser.parse_args()
    try:
        export_app(arguments.cmake, arguments.build_dir.resolve(), arguments.config,
                   arguments.output.absolute())
    except (OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Export failed: {error}\n")
    print(f"Exported application to {arguments.output}")


if __name__ == "__main__":
    main()
