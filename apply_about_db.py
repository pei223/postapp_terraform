import argparse
import os
from pathlib import Path
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--dir", help="directory", default="stg", choices=["stg"], required=False)
parser.add_argument("--files", help="適用したいファイル名をカンマ区切りで指定", required=True)
parser.add_argument("-var-file", help="var file name")

args = parser.parse_args()

dirname = args.dir

dirpath = Path(dirname)
if not dirpath.exists():
  sys.stderr(f"{dirname} is not exist.")
  sys.exit(-1)

filenames = args.files.split(",")

apply_target_args = []
for filename in filenames:
  with open(str(dirpath.joinpath(filename)), "r", encoding="utf-8") as file:
    for line in file:
      field = line.split(" ")
      if field[0] not in ["resource", "data"]:
        continue
      resource_name, specified_name = field[1].replace("\"", ""), field[2].replace("\"", "")
      apply_target_args.append(f"-target={resource_name}.{specified_name}")

apply_commands = ["terraform", "apply"]
if args.var_file:
  apply_commands += [f"-var-file={args.var_file}"]

subprocess.call(apply_commands + apply_target_args, shell=True, cwd=f"./{args.dir}")

