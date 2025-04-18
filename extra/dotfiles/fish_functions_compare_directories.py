#!/usr/bin/env python3

import argparse
import hashlib
import os


def get_file_paths(directory):
    """Recursively get the paths of all files in a directory.

    Parameters
    ----------
    directory : str
        The directory. Can be an absolute or relative path.

    Returns
    -------
    list of str
        The paths of all the files in the directory and its sub-directories.

    """
    paths = []

    for root_dir, _, filenames in os.walk(directory):
        for filename in filenames:
            file_path = os.path.join(root_dir, filename)
            if not os.path.islink(file_path):
                relative_path = os.path.relpath(file_path, start=directory)
                paths.append(relative_path)

    return sorted(paths)


def get_checksum(path):
    """Get the checksum for a file, prefixed with the hash type.

    Parameters
    ----------
    path : str
        The path of a file.

    Returns
    -------
    str
        The checksum of the file at the path, prefixed with the hash type. For
        example: "sha512-b24a099...844c3f3"

    """
    _hash = hashlib.sha512()
    chunk_size = 1024 * 1024

    with open(path, "rb") as _file:
        for chunk in iter(lambda: _file.read(chunk_size), b""):
            _hash.update(chunk)

    return "{}-{}".format(_hash.name, _hash.hexdigest())


def get_modified_time(path):
    """Get the modified time for the file.

    Parameters
    ----------
    path : str
        The path of a file.

    Returns
    -------
    float
        The file's modified time in seconds since the epoch.

    """

    return os.stat(path).st_mtime


#
parser = argparse.ArgumentParser()
parser.add_argument("directory_1")
parser.add_argument("directory_2")
args = parser.parse_args()

directory_1 = args.directory_1
directory_2 = args.directory_2

directory_1_file_paths = get_file_paths(directory_1)
directory_2_file_paths = get_file_paths(directory_2)

print(f"{directory_1}: {len(directory_1_file_paths)} files")
print(f"{directory_2}: {len(directory_2_file_paths)} files")
print()

# Handle the presence of different files in the directories.
if directory_1_file_paths != directory_2_file_paths:
    print("The filename in the directories do not match.")
    print()

    extra_files_in_directory_2 = list(
        set(directory_2_file_paths).difference(directory_1_file_paths)
    )
    if extra_files_in_directory_2:
        print(f"Files in {directory_2} which are not in {directory_1}:")
        for filename in extra_files_in_directory_2:
            print(f"* {filename}")

    extra_files_in_directory_1 = list(
        set(directory_1_file_paths).difference(directory_2_file_paths)
    )
    if extra_files_in_directory_1:
        print(f"Files in {directory_1} which are not in {directory_2}:")
        for filename in extra_files_in_directory_1:
            print(f"* {filename}")

    exit(1)

checked_count = 0
total_count = len(directory_1_file_paths)
hash_mismatches = []
modified_time_mismatches = []
for relative_file_path in directory_1_file_paths:
    checked_count += 1
    print("\033[K", end="")
    print(
        f"Checking {relative_file_path} | File {checked_count} of {total_count} | "
        f"{len(hash_mismatches)} hash mismatches found |",
        end="\r",
    )

    directory_1_file_path = os.path.join(directory_1, relative_file_path)
    directory_2_file_path = os.path.join(directory_2, relative_file_path)

    directory_1_file_hash = get_checksum(directory_1_file_path)
    directory_2_file_hash = get_checksum(directory_2_file_path)
    if directory_1_file_hash != directory_2_file_hash:
        hash_mismatches.append(relative_file_path)

    directory_1_file_modified_time = get_modified_time(directory_1_file_path)
    directory_2_file_modified_time = get_modified_time(directory_2_file_path)
    if directory_1_file_modified_time != directory_2_file_modified_time:
        modified_time_mismatches.append(relative_file_path)

print()

if len(hash_mismatches) == 0:
    print(f"All {checked_count} files checked have identical contents.")
else:
    print()
    if len(hash_mismatches) == 1:
        print("There was 1 file with mis-matched contents:")
    else:
        print(f"There were {len(hash_mismatches)} files with mis-matched contents:")
    for hash_mismatch in hash_mismatches:
        print(f"* {hash_mismatch}")

if len(modified_time_mismatches) == 0:
    print(f"All {checked_count} files checked have identical modified times.")
else:
    print()
    if len(modified_time_mismatches) == 1:
        print("There was 1 file with mis-matched modified times:")
    else:
        print(
            f"There were {len(modified_time_mismatches)} files with mis-matched modified times:"
        )
    for modified_time_mismatch in modified_time_mismatches:
        print(f"* {modified_time_mismatch}")


if len(hash_mismatches) > 0 or len(modified_time_mismatches) > 0:
    exit(1)
